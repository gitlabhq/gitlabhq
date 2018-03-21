module Ci
  class Pipeline < ActiveRecord::Base
    extend Gitlab::Ci::Model
    include HasStatus
    include Importable
    include AfterCommitQueue
    include Presentable
    include Gitlab::OptimisticLocking
    include Gitlab::Utils::StrongMemoize

    belongs_to :project, inverse_of: :pipelines
    belongs_to :user
    belongs_to :auto_canceled_by, class_name: 'Ci::Pipeline'
    belongs_to :pipeline_schedule, class_name: 'Ci::PipelineSchedule'

    has_many :stages
    has_many :statuses, class_name: 'CommitStatus', foreign_key: :commit_id, inverse_of: :pipeline
    has_many :builds, foreign_key: :commit_id
    has_many :trigger_requests, dependent: :destroy, foreign_key: :commit_id # rubocop:disable Cop/ActiveRecordDependent
    has_many :variables, class_name: 'Ci::PipelineVariable'

    # Merge requests for which the current pipeline is running against
    # the merge request's latest commit.
    has_many :merge_requests, foreign_key: "head_pipeline_id"

    has_many :pending_builds, -> { pending }, foreign_key: :commit_id, class_name: 'Ci::Build'
    has_many :retryable_builds, -> { latest.failed_or_canceled.includes(:project) }, foreign_key: :commit_id, class_name: 'Ci::Build'
    has_many :cancelable_statuses, -> { cancelable }, foreign_key: :commit_id, class_name: 'CommitStatus'
    has_many :manual_actions, -> { latest.manual_actions.includes(:project) }, foreign_key: :commit_id, class_name: 'Ci::Build'
    has_many :artifacts, -> { latest.with_artifacts_not_expired.includes(:project) }, foreign_key: :commit_id, class_name: 'Ci::Build'

    has_many :auto_canceled_pipelines, class_name: 'Ci::Pipeline', foreign_key: 'auto_canceled_by_id'
    has_many :auto_canceled_jobs, class_name: 'CommitStatus', foreign_key: 'auto_canceled_by_id'

    delegate :id, to: :project, prefix: true
    delegate :full_path, to: :project, prefix: true

    validates :source, exclusion: { in: %w(unknown), unless: :importing? }, on: :create
    validates :sha, presence: { unless: :importing? }
    validates :ref, presence: { unless: :importing? }
    validates :status, presence: { unless: :importing? }
    validate :valid_commit_sha, unless: :importing?

    after_create :keep_around_commits, unless: :importing?

    enum source: {
      unknown: nil,
      push: 1,
      web: 2,
      trigger: 3,
      schedule: 4,
      api: 5,
      external: 6
    }

    enum config_source: {
      unknown_source: nil,
      repository_source: 1,
      auto_devops_source: 2
    }

    enum failure_reason: {
      unknown_failure: 0,
      config_error: 1
    }

    state_machine :status, initial: :created do
      event :enqueue do
        transition [:created, :skipped] => :pending
        transition [:success, :failed, :canceled] => :running
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

      before_transition any => [:manual] do |pipeline|
        pipeline.update_duration
      end

      before_transition canceled: any - [:canceled] do |pipeline|
        pipeline.auto_canceled_by = nil
      end

      before_transition any => :failed do |pipeline, transition|
        transition.args.first.try do |reason|
          pipeline.failure_reason = reason
        end
      end

      after_transition [:created, :pending] => :running do |pipeline|
        pipeline.run_after_commit { PipelineMetricsWorker.perform_async(pipeline.id) }
      end

      after_transition any => [:success] do |pipeline|
        pipeline.run_after_commit { PipelineMetricsWorker.perform_async(pipeline.id) }
      end

      after_transition [:created, :pending, :running] => :success do |pipeline|
        pipeline.run_after_commit { PipelineSuccessWorker.perform_async(pipeline.id) }
      end

      after_transition do |pipeline, transition|
        next if transition.loopback?

        pipeline.run_after_commit do
          PipelineHooksWorker.perform_async(pipeline.id)
          ExpirePipelineCacheWorker.perform_async(pipeline.id)
        end
      end

      after_transition any => [:success, :failed] do |pipeline|
        pipeline.run_after_commit do
          PipelineNotificationWorker.perform_async(pipeline.id)
        end
      end
    end

    scope :internal, -> { where(source: internal_sources) }

    # Returns the pipelines in descending order (= newest first), optionally
    # limited to a number of references.
    #
    # ref - The name (or names) of the branch(es)/tag(s) to limit the list of
    #       pipelines to.
    def self.newest_first(ref = nil)
      relation = order(id: :desc)

      ref ? relation.where(ref: ref) : relation
    end

    def self.latest_status(ref = nil)
      newest_first(ref).pluck(:status).first
    end

    def self.latest_successful_for(ref)
      newest_first(ref).success.take
    end

    def self.latest_successful_for_refs(refs)
      relation = newest_first(refs).success

      relation.each_with_object({}) do |pipeline, hash|
        hash[pipeline.ref] ||= pipeline
      end
    end

    # Returns a Hash containing the latest pipeline status for every given
    # commit.
    #
    # The keys of this Hash are the commit SHAs, the values the statuses.
    #
    # commits - The list of commit SHAs to get the status for.
    # ref - The ref to scope the data to (e.g. "master"). If the ref is not
    #       given we simply get the latest status for the commits, regardless
    #       of what refs their pipelines belong to.
    def self.latest_status_per_commit(commits, ref = nil)
      p1 = arel_table
      p2 = arel_table.alias

      # This LEFT JOIN will filter out all but the newest row for every
      # combination of (project_id, sha) or (project_id, sha, ref) if a ref is
      # given.
      cond = p1[:sha].eq(p2[:sha])
        .and(p1[:project_id].eq(p2[:project_id]))
        .and(p1[:id].lt(p2[:id]))

      cond = cond.and(p1[:ref].eq(p2[:ref])) if ref
      join = p1.join(p2, Arel::Nodes::OuterJoin).on(cond)

      relation = select(:sha, :status)
        .where(sha: commits)
        .where(p2[:id].eq(nil))
        .joins(join.join_sources)

      relation = relation.where(ref: ref) if ref

      relation.each_with_object({}) do |row, hash|
        hash[row[:sha]] = row[:status]
      end
    end

    def self.truncate_sha(sha)
      sha[0...8]
    end

    def self.total_duration
      where.not(duration: nil).sum(:duration)
    end

    def self.internal_sources
      sources.reject { |source| source == "external" }.values
    end

    def stages_count
      statuses.select(:stage).distinct.count
    end

    def total_size
      statuses.count(:id)
    end

    def stages_names
      statuses.order(:stage_idx).distinct
        .pluck(:stage, :stage_idx).map(&:first)
    end

    def legacy_stage(name)
      stage = Ci::LegacyStage.new(self, name: name)
      stage unless stage.statuses_count.zero?
    end

    def legacy_stages
      # TODO, this needs refactoring, see gitlab-ce#26481.

      stages_query = statuses
        .group('stage').select(:stage).order('max(stage_idx)')

      status_sql = statuses.latest.where('stage=sg.stage').status_sql

      warnings_sql = statuses.latest.select('COUNT(*)')
        .where('stage=sg.stage').failed_but_allowed.to_sql

      stages_with_statuses = CommitStatus.from(stages_query, :sg)
        .pluck('sg.stage', status_sql, "(#{warnings_sql})")

      stages_with_statuses.map do |stage|
        Ci::LegacyStage.new(self, Hash[%i[name status warnings].zip(stage)])
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

    # NOTE: This is loaded lazily and will never be nil, even if the commit
    # cannot be found.
    #
    # Use constructs like: `pipeline.commit.present?`
    def commit
      @commit ||= Commit.lazy(project, sha)
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
      retry_optimistic_lock(cancelable_statuses) do |cancelable|
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
      return false unless ref && commit.present?

      project.commit(ref) == commit
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

    def stage_seeds
      return [] unless config_processor

      @stage_seeds ||= config_processor.stage_seeds(self)
    end

    def seeds_size
      @seeds_size ||= stage_seeds.sum(&:size)
    end

    def has_kubernetes_active?
      project.deployment_platform&.active?
    end

    def has_stage_seeds?
      stage_seeds.any?
    end

    def has_warnings?
      builds.latest.failed_but_allowed.any?
    end

    def set_config_source
      if ci_yaml_from_repo
        self.config_source = :repository_source
      elsif implied_ci_yaml_file
        self.config_source = :auto_devops_source
      end
    end

    def config_processor
      return unless ci_yaml_file
      return @config_processor if defined?(@config_processor)

      @config_processor ||= begin
        Gitlab::Ci::YamlProcessor.new(ci_yaml_file)
      rescue Gitlab::Ci::YamlProcessor::ValidationError => e
        self.yaml_errors = e.message
        nil
      rescue
        self.yaml_errors = 'Undefined error'
        nil
      end
    end

    def ci_yaml_file_path
      if project.ci_config_path.blank?
        '.gitlab-ci.yml'
      else
        project.ci_config_path
      end
    end

    def ci_yaml_file
      return @ci_yaml_file if defined?(@ci_yaml_file)

      @ci_yaml_file =
        if auto_devops_source?
          implied_ci_yaml_file
        else
          ci_yaml_from_repo
        end

      if @ci_yaml_file
        @ci_yaml_file
      else
        self.yaml_errors = "Failed to load CI/CD config file for #{sha}"
        nil
      end
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
      project.notes.for_commit_id(sha)
    end

    def process!
      Ci::ProcessPipelineService.new(project, user).execute(self)
    end

    def update_status
      retry_optimistic_lock(self) do
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

    # TODO specs
    #
    def protected_ref?
      strong_memoize(:protected_ref) { project.protected_for?(ref) }
    end

    # TODO specs
    #
    def legacy_trigger
      strong_memoize(:legacy_trigger) { trigger_requests.first }
    end

    def predefined_variables
      Gitlab::Ci::Variables::Collection.new
        .append(key: 'CI_PIPELINE_ID', value: id.to_s)
        .append(key: 'CI_CONFIG_PATH', value: ci_yaml_file_path)
        .append(key: 'CI_PIPELINE_SOURCE', value: source.to_s)
    end

    def queued_duration
      return unless started_at

      seconds = (started_at - created_at).to_i
      seconds unless seconds.zero?
    end

    def update_duration
      return unless started_at

      self.duration = Gitlab::Ci::Pipeline::Duration.from_pipeline(self)
    end

    def execute_hooks
      data = pipeline_data
      project.execute_hooks(data, :pipeline_hooks)
      project.execute_services(data, :pipeline_hooks)
    end

    # All the merge requests for which the current pipeline runs/ran against
    def all_merge_requests
      @all_merge_requests ||= project.merge_requests.where(source_branch: ref)
    end

    def detailed_status(current_user)
      Gitlab::Ci::Status::Pipeline::Factory
        .new(self, current_user)
        .fabricate!
    end

    def latest_builds_with_artifacts
      # We purposely cast the builds to an Array here. Because we always use the
      # rows if there are more than 0 this prevents us from having to run two
      # queries: one to get the count and one to get the rows.
      @latest_builds_with_artifacts ||= builds.latest.with_artifacts_archive.to_a
    end

    private

    def ci_yaml_from_repo
      return unless project
      return unless sha

      project.repository.gitlab_ci_yml_for(sha, ci_yaml_file_path)
    rescue GRPC::NotFound, GRPC::Internal
      nil
    end

    def implied_ci_yaml_file
      return unless project

      if project.auto_devops_enabled?
        Gitlab::Template::GitlabCiYmlTemplate.find('Auto-DevOps').content
      end
    end

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
