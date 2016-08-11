module Ci
  class Pipeline < ActiveRecord::Base
    extend Ci::Model
    include Statuseable

    self.table_name = 'ci_commits'

    belongs_to :project, class_name: '::Project', foreign_key: :gl_project_id
    belongs_to :user

    has_many :statuses, class_name: 'CommitStatus', foreign_key: :commit_id
    has_many :builds, class_name: 'Ci::Build', foreign_key: :commit_id
    has_many :trigger_requests, dependent: :destroy, class_name: 'Ci::TriggerRequest', foreign_key: :commit_id

    validates_presence_of :sha
    validates_presence_of :ref
    validates_presence_of :status
    validate :valid_commit_sha

    after_save :keep_around_commits

    state_machine :status, initial: :created do
      event :skip do
        transition any => :skipped
      end

      event :drop do
        transition any => :failed
      end

      event :update_status do
        transition any => :pending, if: ->(pipeline) { pipeline.can_transition_to?('pending') }
        transition any => :running, if: ->(pipeline) { pipeline.can_transition_to?('running') }
        transition any => :failed, if: ->(pipeline) { pipeline.can_transition_to?('failed') }
        transition any => :success, if: ->(pipeline) { pipeline.can_transition_to?('success') }
        transition any => :canceled, if: ->(pipeline) { pipeline.can_transition_to?('canceled') }
        transition any => :skipped, if: ->(pipeline) { pipeline.can_transition_to?('skipped') }
      end

      after_transition [:created, :pending] => :running do |pipeline|
        pipeline.update(started_at: Time.now)
      end

      after_transition any => [:success, :failed, :canceled] do |pipeline|
        pipeline.update(finished_at: Time.now)
      end

      after_transition do |pipeline|
        pipeline.update_duration
      end
    end

    # ref can't be HEAD or SHA, can only be branch/tag name
    scope :latest_successful_for, ->(ref = default_branch) do
      where(ref: ref).success.order(id: :desc).limit(1)
    end

    def self.truncate_sha(sha)
      sha[0...8]
    end

    def self.stages
      # We use pluck here due to problems with MySQL which doesn't allow LIMIT/OFFSET in queries
      CommitStatus.where(pipeline: pluck(:id)).stages
    end

    def project_id
      project.id
    end

    def valid_commit_sha
      if self.sha == Gitlab::Git::BLANK_SHA
        self.errors.add(:sha, " cant be 00000000 (branch removal)")
      end
    end

    def git_author_name
      commit.try(:author_name)
    end

    def git_author_email
      commit.try(:author_email)
    end

    def git_commit_message
      commit.try(:message)
    end

    def git_commit_title
      commit.try(:title)
    end

    def short_sha
      Ci::Pipeline.truncate_sha(sha)
    end

    def commit
      @commit ||= project.commit(sha)
    rescue
      nil
    end

    def branch?
      !tag?
    end

    def manual_actions
      builds.latest.manual_actions
    end

    def retryable?
      builds.latest.any? do |build|
        build.failed? && build.retryable?
      end
    end

    def cancelable?
      builds.running_or_pending.any?
    end

    def cancel_running
      builds.running_or_pending.each(&:cancel)
    end

    def retry_failed(user)
      builds.latest.failed.select(&:retryable?).each do |build|
        Ci::Build.retry(build, user)
      end
    end

    def latest?
      return false unless ref
      commit = project.commit(ref)
      return false unless commit
      commit.sha == sha
    end

    def triggered?
      trigger_requests.any?
    end

    def retried
      @retried ||= (statuses.order(id: :desc) - statuses.latest)
    end

    def coverage
      coverage_array = statuses.latest.map(&:coverage).compact
      if coverage_array.size >= 1
        '%.2f' % (coverage_array.reduce(:+) / coverage_array.size)
      end
    end

    def config_builds_attributes
      return [] unless config_processor

      config_processor.
        builds_for_ref(ref, tag?, trigger_requests.first).
        sort_by { |build| build[:stage_idx] }
    end

    def has_warnings?
      builds.latest.ignored.any?
    end

    def config_processor
      return nil unless ci_yaml_file
      return @config_processor if defined?(@config_processor)

      @config_processor ||= begin
        Ci::GitlabCiYamlProcessor.new(ci_yaml_file, project.path_with_namespace)
      rescue Ci::GitlabCiYamlProcessor::ValidationError, Psych::SyntaxError => e
        self.yaml_errors = e.message
        nil
      rescue
        self.yaml_errors = 'Undefined error'
        nil
      end
    end

    def ci_yaml_file
      return @ci_yaml_file if defined?(@ci_yaml_file)

      @ci_yaml_file ||= begin
        blob = project.repository.blob_at(sha, '.gitlab-ci.yml')
        blob.load_all_data!(project.repository)
        blob.data
      rescue
        nil
      end
    end

    def environments
      builds.where.not(environment: nil).success.pluck(:environment).uniq
    end

    # Manually set the notes for a Ci::Pipeline
    # There is no ActiveRecord relation between Ci::Pipeline and notes
    # as they are related to a commit sha. This method helps importing
    # them using the +Gitlab::ImportExport::RelationFactory+ class.
    def notes=(notes)
      notes.each do |note|
        note[:id] = nil
        note[:commit_id] = sha
        note[:noteable_id] = self['id']
        note.save!
      end
    end

    def notes
      Note.for_commit_id(sha)
    end

    def process!
      Ci::ProcessPipelineService.new(project, user).execute(self)
    end

    def predefined_variables
      [
        { key: 'CI_PIPELINE_ID', value: id.to_s, public: true }
      ]
    end

    def can_transition_to?(expected_status)
      latest_status == expected_status
    end

    def update_duration
      update(duration: statuses.latest.duration)
    end

    private

    def latest_status
      return 'failed' unless yaml_errors.blank?

      statuses.latest.status || 'skipped'
    end

    def keep_around_commits
      return unless project

      project.repository.keep_around(self.sha)
      project.repository.keep_around(self.before_sha)
    end
  end
end
