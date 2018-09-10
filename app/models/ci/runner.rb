# frozen_string_literal: true

module Ci
  class Runner < ActiveRecord::Base
    extend Gitlab::Ci::Model
    include Gitlab::SQL::Pattern
    include IgnorableColumn
    include RedisCacheable
    include ChronicDurationAttribute
    include TickableResource

    RUNNER_QUEUE_EXPIRY_TIME = 60.minutes
    ONLINE_CONTACT_TIMEOUT = 1.hour
    UPDATE_DB_RUNNER_INFO_EVERY = 40.minutes
    AVAILABLE_SCOPES = %w[specific shared active paused online].freeze
    FORM_EDITABLE = %i[description tag_list active run_untagged locked access_level maximum_timeout_human_readable].freeze

    ignore_column :is_shared

    has_many :builds
    has_many :runner_projects, inverse_of: :runner, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
    has_many :projects, through: :runner_projects
    has_many :runner_namespaces, inverse_of: :runner
    has_many :groups, through: :runner_namespaces

    has_one :last_build, ->() { order('id DESC') }, class_name: 'Ci::Build'

    before_validation :set_default_values

    scope :active, -> { where(active: true) }
    scope :paused, -> { where(active: false) }
    scope :online, -> { where('contacted_at > ?', contact_time_deadline) }
    scope :ordered, -> { order(id: :desc) }

    # BACKWARD COMPATIBILITY: There are needed to maintain compatibility with `AVAILABLE_SCOPES` used by `lib/api/runners.rb`
    scope :deprecated_shared, -> { instance_type }
    # this should get replaced with `project_type.or(group_type)` once using Rails5
    scope :deprecated_specific, -> { where(runner_type: [runner_types[:project_type], runner_types[:group_type]]) }

    scope :belonging_to_project, -> (project_id) {
      joins(:runner_projects).where(ci_runner_projects: { project_id: project_id })
    }

    scope :belonging_to_parent_group_of_project, -> (project_id) {
      project_groups = ::Group.joins(:projects).where(projects: { id: project_id })
      hierarchy_groups = Gitlab::GroupHierarchy.new(project_groups).base_and_ancestors

      joins(:groups).where(namespaces: { id: hierarchy_groups })
    }

    scope :owned_or_instance_wide, -> (project_id) do
      union = Gitlab::SQL::Union.new(
        [belonging_to_project(project_id), belonging_to_parent_group_of_project(project_id), instance_type],
        remove_duplicates: false
      )
      from("(#{union.to_sql}) ci_runners")
    end

    scope :assignable_for, ->(project) do
      # FIXME: That `to_sql` is needed to workaround a weird Rails bug.
      #        Without that, placeholders would miss one and couldn't match.
      where(locked: false)
        .where.not("ci_runners.id IN (#{project.runners.select(:id).to_sql})")
        .project_type
    end

    add_tickable_resource :runner_queue, expire: RUNNER_QUEUE_EXPIRY_TIME do |runner|
      "runner:build_queue:#{runner.token}"
    end

    add_tickable_resource :runner_details, expire: RUNNER_QUEUE_EXPIRY_TIME, notification_channel: 'runner:notifications' do |runner|
      "runner:details:#{runner.token}"
    end

    validate :tag_constraints
    validates :access_level, presence: true
    validates :runner_type, presence: true

    validate :no_projects, unless: :project_type?
    validate :no_groups, unless: :group_type?
    validate :any_project, if: :project_type?
    validate :exactly_one_group, if: :group_type?

    acts_as_taggable

    after_destroy :cleanup_runner_queue

    enum access_level: {
      not_protected: 0,
      ref_protected: 1
    }

    enum runner_type: {
      instance_type: 1,
      group_type: 2,
      project_type: 3
    }

    cached_attr_reader :version, :revision, :platform, :architecture, :ip_address, :contacted_at

    chronic_duration_attr :maximum_timeout_human_readable, :maximum_timeout

    validates :maximum_timeout, allow_nil: true,
                                numericality: { greater_than_or_equal_to: 600,
                                                message: 'needs to be at least 10 minutes' }

    # Searches for runners matching the given query.
    #
    # This method uses ILIKE on PostgreSQL and LIKE on MySQL.
    #
    # This method performs a *partial* match on tokens, thus a query for "a"
    # will match any runner where the token contains the letter "a". As a result
    # you should *not* use this method for non-admin purposes as otherwise users
    # might be able to query a list of all runners.
    #
    # query - The search query as a String
    #
    # Returns an ActiveRecord::Relation.
    def self.search(query)
      fuzzy_search(query, [:token, :description])
    end

    def self.contact_time_deadline
      ONLINE_CONTACT_TIMEOUT.ago
    end

    def set_default_values
      self.token = SecureRandom.hex(15) if self.token.blank?
    end

    def assign_to(project, current_user = nil)
      if instance_type?
        self.runner_type = :project_type
      elsif group_type?
        raise ArgumentError, 'Transitioning a group runner to a project runner is not supported'
      end

      begin
        transaction do
          self.projects << project
          self.save!
        end
      rescue ActiveRecord::RecordInvalid => e
        self.errors.add(:assign_to, e.message)
        false
      end
    end

    def display_name
      return short_sha if description.blank?

      description
    end

    def online?
      contacted_at && contacted_at > self.class.contact_time_deadline
    end

    def status
      if contacted_at.nil?
        :not_connected
      elsif active?
        online? ? :online : :offline
      else
        :paused
      end
    end

    def belongs_to_one_project?
      runner_projects.count == 1
    end

    def assigned_to_group?
      runner_namespaces.any?
    end

    def assigned_to_project?
      runner_projects.any?
    end

    def can_pick?(build)
      return false if self.ref_protected? && !build.protected?

      assignable_for?(build.project_id) && accepting_tags?(build)
    end

    def only_for?(project)
      projects == [project]
    end

    def short_sha
      token[0...8] if token
    end

    def has_tags?
      tag_list.any?
    end

    def predefined_variables
      Gitlab::Ci::Variables::Collection.new
        .append(key: 'CI_RUNNER_ID', value: id.to_s)
        .append(key: 'CI_RUNNER_DESCRIPTION', value: description)
        .append(key: 'CI_RUNNER_TAGS', value: tag_list.to_s)
    end

    def update_cached_info(values)
      values = values&.slice(:version, :revision, :platform, :architecture, :ip_address) || {}
      values[:contacted_at] = Time.now

      cache_attributes(values)

      # We save data without validation, it will always change due to `contacted_at`
      self.update_columns(values) if persist_cached_data?
    end

    def pick_build!(build)
      if can_pick?(build)
        tick_runner_queue
      end
    end

    def group_filters
      return [] unless self.group_type?

      self.groups.pluck(:id).map do |group_id|
        "group_#{group_id}"
      end
    end

    def project_filters
      return [] unless self.project_type?

      self.projects.pluck(:id).map do |project_id|
        "project_#{project_id}"
      end
    end

    def tag_filters
      self.tag_list.map do |tag_name|
        "tag_#{tag_name}"
      end
    end

    def filters
      filters = []
      filters << :shared if self.instance_type?
      filters += group_filters
      filters += project_filters
      filters += tag_filters
      filters << :protected if self.ref_protected?
      filters << :run_untagged if self.run_untagged?
      filters
    end

    def details
      {
        id: self.id,
        tag_filters: [filters]
      }
    end

    def persist_details!
      key = "runner:details:#{self.token}"

      Gitlab::Redis::Queues.with do |redis|
        redis.set(key, details, ex: RUNNER_QUEUE_EXPIRY_TIME, nx: false)
      end
    end

    private

    def persist_cached_data?
      # Use a random threshold to prevent beating DB updates.
      # It generates a distribution between [40m, 80m].

      contacted_at_max_age = UPDATE_DB_RUNNER_INFO_EVERY + Random.rand(UPDATE_DB_RUNNER_INFO_EVERY)

      real_contacted_at = read_attribute(:contacted_at)
      real_contacted_at.nil? ||
        (Time.now - real_contacted_at) >= contacted_at_max_age
    end

    def tag_constraints
      unless has_tags? || run_untagged?
        errors.add(:tags_list,
          'can not be empty when runner is not allowed to pick untagged jobs')
      end
    end

    def assignable_for?(project_id)
      self.class.owned_or_instance_wide(project_id).where(id: self.id).any?
    end

    def no_projects
      if projects.any?
        errors.add(:runner, 'cannot have projects assigned')
      end
    end

    def no_groups
      if groups.any?
        errors.add(:runner, 'cannot have groups assigned')
      end
    end

    def any_project
      unless projects.any?
        errors.add(:runner, 'needs to be assigned to at least one project')
      end
    end

    def exactly_one_group
      unless groups.one?
        errors.add(:runner, 'needs to be assigned to exactly one group')
      end
    end

    def accepting_tags?(build)
      (run_untagged? || build.has_tags?) && (build.tag_list - tag_list).empty?
    end
  end
end
