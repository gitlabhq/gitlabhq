module Ci
  class Pipeline < ActiveRecord::Base
    extend Ci::Model
    include HasStatus
    include Importable
    include AfterCommitQueue
    include Presentable

    belongs_to :project
    belongs_to :user
    belongs_to :auto_canceled_by, class_name: 'Ci::Pipeline'

    has_many :auto_canceled_pipelines, class_name: 'Ci::Pipeline', foreign_key: 'auto_canceled_by_id'
    has_many :auto_canceled_jobs, class_name: 'CommitStatus', foreign_key: 'auto_canceled_by_id'

    has_many :statuses, class_name: 'CommitStatus', foreign_key: :commit_id
    has_many :builds, foreign_key: :commit_id
    has_many :trigger_requests, dependent: :destroy, foreign_key: :commit_id

    has_many :pending_builds, -> { pending }, foreign_key: :commit_id, class_name: 'Ci::Build'
    has_many :retryable_builds, -> { latest.failed_or_canceled }, foreign_key: :commit_id, class_name: 'Ci::Build'
    has_many :cancelable_statuses, -> { cancelable }, foreign_key: :commit_id, class_name: 'CommitStatus'
    has_many :manual_actions, -> { latest.manual_actions }, foreign_key: :commit_id, class_name: 'Ci::Build'
    has_many :artifacts, -> { latest.with_artifacts_not_expired }, foreign_key: :commit_id, class_name: 'Ci::Build'

    delegate :id, to: :project, prefix: true

    validates :sha, presence: { unless: :importing? }
    validates :ref, presence: { unless: :importing? }
    validates :status, presence: { unless: :importing? }
    validate :valid_commit_sha, unless: :importing?

    after_create :keep_around_commits, unless: :importing?

    state_machine :status, initial: :created do
      event :enqueue do
        transition created: :pending
        transition [:success, :failed, :canceled, :skipped] => :running
      end

      event :run do
        transition any - [:running] => :running
      end

      event :skip do
        transition any - [:skipped] => :skipped
      end

      event :drop do
        transition any - [:failed] => :failed
      end

      event :succeed do
        transition any - [:success] => :success
      end

      event :cancel do
        transition any - [:canceled] => :canceled
      end

      event :block do
        transition any - [:manual] => :manual
      end

      # IMPORTANT
      # Do not add any operations to this state_machine
      # Create a separate worker for each new operation

      before_transition [:created, :pending] => :running do |pipeline|
        pipeline.started_at = Time.now
      end

      before_transition any => [:success, :failed, :canceled] do |pipeline|
        pipeline.finished_at = Time.now
        pipeline.update_duration
      end

      before_transition canceled: any - [:canceled] do |pipeline|
        pipeline.auto_canceled_by = nil
      end

      after_transition [:created, :pending] => :running do |pipeline|
        pipeline.run_after_commit { PipelineMetricsWorker.perform_async(id) }
      end

      after_transition any => [:success] do |pipeline|
        pipeline.run_after_commit { PipelineMetricsWorker.perform_async(id) }
      end

      after_transition [:created, :pending, :running] => :success do |pipeline|
        pipeline.run_after_commit { PipelineSuccessWorker.perform_async(id) }
      end

      after_transition do |pipeline, transition|
        next if transition.loopback?

        pipeline.run_after_commit do
          PipelineHooksWorker.perform_async(id)
          ExpirePipelineCacheWorker.perform_async(pipeline.id)
        end
      end

      after_transition any => [:success, :failed] do |pipeline|
        pipeline.run_after_commit do
          PipelineNotificationWorker.perform_async(pipeline.id)
        end
      end
    end

    # ref can't be HEAD or SHA, can only be branch/tag name
    scope :latest, ->(ref = nil) do
      max_id = unscope(:select)
        .select("max(#{quoted_table_name}.id)")
        .group(:ref, :sha)

      if ref
        where(ref: ref, id: max_id.where(ref: ref))
      else
        where(id: max_id)
      end
    end

    def self.latest_status(ref = nil)
      latest(ref).status
    end

    def self.latest_successful_for(ref)
      success.latest(ref).order(id: :desc).first
    end

    def self.latest_successful_for_refs(refs)
      success.latest(refs).order(id: :desc).each_with_object({}) do |pipeline, hash|
        hash[pipeline.ref] ||= pipeline
      end
    end

    def self.truncate_sha(sha)
      sha[0...8]
    end

    def self.total_duration
      where.not(duration: nil).sum(:duration)
    end

    def stage(name)
      stage = Ci::Stage.new(self, name: name)
      stage unless stage.statuses_count.zero?
    end

    def stages_count
      statuses.select(:stage).distinct.count
    end

    def stages_name
      statuses.order(:stage_idx).distinct.
        pluck(:stage, :stage_idx).map(&:first)
    end

    def stages
      # TODO, this needs refactoring, see gitlab-ce#26481.

      stages_query = statuses
        .group('stage').select(:stage).order('max(stage_idx)')

      status_sql = statuses.latest.where('stage=sg.stage').status_sql

      warnings_sql = statuses.latest.select('COUNT(*)')
        .where('stage=sg.stage').failed_but_allowed.to_sql

      stages_with_statuses = CommitStatus.from(stages_query, :sg)
        .pluck('sg.stage', status_sql, "(#{warnings_sql})")

      stages_with_statuses.map do |stage|
        Ci::Stage.new(self, Hash[%i[name status warnings].zip(stage)])
      end
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

    def stuck?
      pending_builds.any?(&:stuck?)
    end

    def retryable?
      retryable_builds.any?
    end

    def cancelable?
      cancelable_statuses.any?
    end

    def auto_canceled?
      canceled? && auto_canceled_by_id?
    end

    def cancel_running
      Gitlab::OptimisticLocking.retry_lock(cancelable_statuses) do |cancelable|
        cancelable.find_each do |job|
          yield(job) if block_given?
          job.cancel
        end
      end
    end

    def auto_cancel_running(pipeline)
      update(auto_canceled_by: pipeline)

      cancel_running do |job|
        job.auto_canceled_by = pipeline
      end
    end

    def retry_failed(current_user)
      Ci::RetryPipelineService.new(project, current_user)
        .execute(self)
    end

    def mark_as_processable_after_stage(stage_idx)
      builds.skipped.after_stage(stage_idx).find_each(&:process)
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
      builds.latest.failed_but_allowed.any?
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

      @ci_yaml_file = project.repository.gitlab_ci_yml_for(sha) rescue nil
    end

    def has_yaml_errors?
      yaml_errors.present?
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

    def update_status
      Gitlab::OptimisticLocking.retry_lock(self) do
        case latest_builds_status
        when 'pending' then enqueue
        when 'running' then run
        when 'success' then succeed
        when 'failed' then drop
        when 'canceled' then cancel
        when 'skipped' then skip
        when 'manual' then block
        end
      end
    end

    def predefined_variables
      [
        { key: 'CI_PIPELINE_ID', value: id.to_s, public: true }
      ]
    end

    def queued_duration
      return unless started_at

      seconds = (started_at - created_at).to_i
      seconds unless seconds.zero?
    end

    def update_duration
      return unless started_at

      self.duration = Gitlab::Ci::PipelineDuration.from_pipeline(self)
    end

    def execute_hooks
      data = pipeline_data
      project.execute_hooks(data, :pipeline_hooks)
      project.execute_services(data, :pipeline_hooks)
    end

    # Merge requests for which the current pipeline is running against
    # the merge request's latest commit.
    def merge_requests
      @merge_requests ||= project.merge_requests
        .where(source_branch: self.ref)
        .select { |merge_request| merge_request.head_pipeline.try(:id) == self.id }
    end

    # All the merge requests for which the current pipeline runs/ran against
    def all_merge_requests
      @all_merge_requests ||= project.merge_requests
        .where(source_branch: ref)
        .select { |merge_request| merge_request.all_pipelines.includes(self) }
    end

    def detailed_status(current_user)
      Gitlab::Ci::Status::Pipeline::Factory
        .new(self, current_user)
        .fabricate!
    end

    private

    def pipeline_data
      Gitlab::DataBuilder::Pipeline.build(self)
    end

    def latest_builds_status
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
