# frozen_string_literal: true

module DesignManagement
  class Version < ApplicationRecord
    include Importable
    include ShaAttribute
    include AfterCommitQueue
    include Gitlab::Utils::StrongMemoize
    include EachBatch
    extend Gitlab::ExclusiveLeaseHelpers

    NotSameIssue = Class.new(StandardError)

    class CouldNotCreateVersion < StandardError
      attr_reader :sha, :issue_id, :actions

      def initialize(sha, issue_id, actions)
        @sha = sha
        @issue_id = issue_id
        @actions = actions
      end

      def message
        "could not create version from commit: #{sha}"
      end

      def sentry_extra_data
        {
          sha: sha,
          issue_id: issue_id,
          design_ids: actions.map { |a| a.design.id }
        }
      end
    end

    belongs_to :issue
    belongs_to :author, class_name: 'User'
    has_many :actions
    has_many :designs,
      through: :actions,
      class_name: "DesignManagement::Design",
      source: :design,
      inverse_of: :versions

    validates :designs, presence: true, unless: :importing?
    validates :sha, presence: true
    validates :sha, uniqueness: { case_sensitive: false, scope: :issue_id }
    validates :author, presence: true
    validates :issue, presence: true, unless: :importing?

    sha_attribute :sha

    delegate :project, to: :issue

    scope :for_designs, ->(designs) do
      where(id: DesignManagement::Action.where(design_id: designs).select(:version_id)).distinct
    end
    scope :earlier_or_equal_to, ->(version) { where("(#{table_name}.id) <= ?", version) } # rubocop:disable GitlabSecurity/SqlInjection
    scope :ordered, -> { order(id: :desc) }
    scope :for_issue, ->(issue) { where(issue: issue) }
    scope :by_sha, ->(sha) { where(sha: sha) }
    scope :with_author, -> { includes(:author) }

    # This is the one true way to create a Version.
    #
    # This method means you can avoid the paradox of versions being invalid without
    # designs, and not being able to add designs without a saved version. Also this
    # method inserts designs in bulk, rather than one by one.
    #
    # Before calling this method, callers must guard against concurrent
    # modification by obtaining the lock on the design repository. See:
    # `DesignManagement::Version.with_lock`.
    #
    # Parameters:
    # - design_actions [DesignManagement::DesignAction]:
    #     the actions that have been performed in the repository.
    # - sha [String]:
    #     the SHA of the commit that performed them
    # - author [User]:
    #     the user who performed the commit
    # returns [DesignManagement::Version]
    def self.create_for_designs(design_actions, sha, author)
      issue_id, not_uniq = design_actions.map(&:issue_id).compact.uniq
      raise NotSameIssue, 'All designs must belong to the same issue!' if not_uniq

      transaction do
        version = new(sha: sha, issue_id: issue_id, author: author)
        version.save(validate: false) # We need it to have an ID. Validate later when designs are present

        rows = design_actions.map { |action| action.row_attrs(version) }

        ApplicationRecord.legacy_bulk_insert(DesignManagement::Action.table_name, rows) # rubocop:disable Gitlab/BulkInsert
        version.designs.reset
        version.validate!
        design_actions.each(&:performed)

        version
      end
    rescue StandardError
      raise CouldNotCreateVersion.new(sha, issue_id, design_actions)
    end

    CREATION_TTL = 5.seconds
    RETRY_DELAY = ->(num) { 0.2.seconds * (num**2) }
    LOCK_RETRY_COUNT = 5

    def self.with_lock(project_id, repository, &block)
      key = "with_lock:#{name}:{#{project_id}}"

      in_lock(key, ttl: CREATION_TTL, retries: LOCK_RETRY_COUNT, sleep_sec: RETRY_DELAY) do |_retried|
        repository.create_if_not_exists
        yield
      end
    end

    def designs_by_event
      actions
        .includes(:design)
        .group_by(&:event)
        .transform_values { |group| group.map(&:design) }
    end

    def author
      super || (commit_author if persisted?)
    end

    def diff_refs
      strong_memoize(:diff_refs) { commit&.diff_refs }
    end

    def reset
      %i[diff_refs commit].each { |k| clear_memoization(k) }
      super
    end

    private

    def commit_author
      commit&.author
    end

    def commit
      strong_memoize(:commit) { issue.project.design_repository.commit(sha) }
    end
  end
end
