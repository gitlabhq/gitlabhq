module Ci
  class Runner < ActiveRecord::Base
    extend Ci::Model

    LAST_CONTACT_TIME = 5.minutes.ago
    AVAILABLE_SCOPES = %w[specific shared active paused online]
    FORM_EDITABLE = %i[description tag_list active run_untagged locked]

    has_many :builds, class_name: 'Ci::Build'
    has_many :runner_projects, dependent: :destroy, class_name: 'Ci::RunnerProject'
    has_many :projects, through: :runner_projects, class_name: '::Project', foreign_key: :gl_project_id

    has_one :last_build, ->() { order('id DESC') }, class_name: 'Ci::Build'

    before_validation :set_default_values

    scope :specific, ->() { where(is_shared: false) }
    scope :shared, ->() { where(is_shared: true) }
    scope :active, ->() { where(active: true) }
    scope :paused, ->() { where(active: false) }
    scope :online, ->() { where('contacted_at > ?', LAST_CONTACT_TIME) }
    scope :ordered, ->() { order(id: :desc) }

    scope :owned_or_shared, ->(project_id) do
      joins('LEFT JOIN ci_runner_projects ON ci_runner_projects.runner_id = ci_runners.id')
        .where("ci_runner_projects.gl_project_id = :project_id OR ci_runners.is_shared = true", project_id: project_id)
    end

    scope :assignable_for, ->(project) do
      # FIXME: That `to_sql` is needed to workaround a weird Rails bug.
      #        Without that, placeholders would miss one and couldn't match.
      where(locked: false).
        where.not("id IN (#{project.runners.select(:id).to_sql})").specific
    end

    validate :tag_constraints

    acts_as_taggable

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
      contacted_at && contacted_at > LAST_CONTACT_TIME
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

    private

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
