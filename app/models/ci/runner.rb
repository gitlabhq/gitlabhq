module Ci
  class Runner < ActiveRecord::Base
    extend Ci::Model
    prepend EE::Ci::Runner

    RUNNER_QUEUE_EXPIRY_TIME = 60.minutes
    ONLINE_CONTACT_TIMEOUT = 1.hour
    AVAILABLE_SCOPES = %w[specific shared active paused online].freeze
    FORM_EDITABLE = %i[description tag_list active run_untagged locked].freeze

    has_many :builds
    has_many :runner_projects, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
    has_many :projects, through: :runner_projects

    has_one :last_build, ->() { order('id DESC') }, class_name: 'Ci::Build'

    before_validation :set_default_values

    scope :specific, ->() { where(is_shared: false) }
    scope :shared, ->() { where(is_shared: true) }
    scope :active, ->() { where(active: true) }
    scope :paused, ->() { where(active: false) }
    scope :online, ->() { where('contacted_at > ?', contact_time_deadline) }
    scope :ordered, ->() { order(id: :desc) }

    scope :owned_or_shared, ->(project_id) do
      joins('LEFT JOIN ci_runner_projects ON ci_runner_projects.runner_id = ci_runners.id')
        .where("ci_runner_projects.project_id = :project_id OR ci_runners.is_shared = true", project_id: project_id)
    end

    scope :assignable_for, ->(project) do
      # FIXME: That `to_sql` is needed to workaround a weird Rails bug.
      #        Without that, placeholders would miss one and couldn't match.
      where(locked: false)
        .where.not("id IN (#{project.runners.select(:id).to_sql})").specific
    end

    validate :tag_constraints

    acts_as_taggable

    after_destroy :cleanup_runner_queue

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
      t = arel_table
      pattern = "%#{query}%"

      where(t[:token].matches(pattern).or(t[:description].matches(pattern)))
    end

    def self.contact_time_deadline
      ONLINE_CONTACT_TIMEOUT.ago
    end

    def set_default_values
      self.token = SecureRandom.hex(15) if self.token.blank?
    end

    def assign_to(project, current_user = nil)
      self.is_shared = false if shared?
      self.save
      project.runner_projects.create(runner_id: self.id)
    end

    def display_name
      return short_sha if description.blank?

      description
    end

    def shared?
      is_shared
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

    def specific?
      !shared?
    end

    def can_pick?(build)
      assignable_for?(build.project) && accepting_tags?(build)
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
      [
        { key: 'CI_RUNNER_ID', value: id.to_s, public: true },
        { key: 'CI_RUNNER_DESCRIPTION', value: description, public: true },
        { key: 'CI_RUNNER_TAGS', value: tag_list.to_s, public: true }
      ]
    end

    def tick_runner_queue
      SecureRandom.hex.tap do |new_update|
        ::Gitlab::Workhorse.set_key_and_notify(runner_queue_key, new_update,
          expire: RUNNER_QUEUE_EXPIRY_TIME, overwrite: true)
      end
    end

    def ensure_runner_queue_value
      new_value = SecureRandom.hex
      ::Gitlab::Workhorse.set_key_and_notify(runner_queue_key, new_value,
        expire: RUNNER_QUEUE_EXPIRY_TIME, overwrite: false)
    end

    def is_runner_queue_value_latest?(value)
      ensure_runner_queue_value == value if value.present?
    end

    private

    def cleanup_runner_queue
      Gitlab::Redis::Queues.with do |redis|
        redis.del(runner_queue_key)
      end
    end

    def runner_queue_key
      "runner:build_queue:#{self.token}"
    end

    def tag_constraints
      unless has_tags? || run_untagged?
        errors.add(:tags_list,
          'can not be empty when runner is not allowed to pick untagged jobs')
      end
    end

    def assignable_for?(project)
      !locked? || projects.exists?(id: project.id)
    end

    def accepting_tags?(build)
      (run_untagged? || build.has_tags?) && (build.tag_list - tag_list).empty?
    end
  end
end
