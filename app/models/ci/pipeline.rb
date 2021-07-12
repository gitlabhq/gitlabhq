# frozen_string_literal: true

module Ci
  class Pipeline < ApplicationRecord
    extend Gitlab::Ci::Model
    include Ci::HasStatus
    include Importable
    include AfterCommitQueue
    include Presentable
    include Gitlab::Allowable
    include Gitlab::OptimisticLocking
    include Gitlab::Utils::StrongMemoize
    include AtomicInternalId
    include EnumWithNil
    include Ci::HasRef
    include ShaAttribute
    include FromUnion
    include UpdatedAtFilterable
    include EachBatch
    include FastDestroyAll::Helpers

    MAX_OPEN_MERGE_REQUESTS_REFS = 4

    PROJECT_ROUTE_AND_NAMESPACE_ROUTE = {
      project: [:project_feature, :route, { namespace: :route }]
    }.freeze
    CONFIG_EXTENSION = '.gitlab-ci.yml'
    DEFAULT_CONFIG_PATH = CONFIG_EXTENSION

    BridgeStatusError = Class.new(StandardError)

    paginates_per 15

    sha_attribute :source_sha
    sha_attribute :target_sha

    # Ci::CreatePipelineService returns Ci::Pipeline so this is the only place
    # where we can pass additional information from the service. This accessor
    # is used for storing the processed CI YAML contents for linting purposes.
    # There is an open issue to address this:
    # https://gitlab.com/gitlab-org/gitlab/-/issues/259010
    attr_accessor :merged_yaml

    belongs_to :project, inverse_of: :all_pipelines
    belongs_to :user
    belongs_to :auto_canceled_by, class_name: 'Ci::Pipeline'
    belongs_to :pipeline_schedule, class_name: 'Ci::PipelineSchedule'
    belongs_to :merge_request, class_name: 'MergeRequest'
    belongs_to :external_pull_request
    belongs_to :ci_ref, class_name: 'Ci::Ref', foreign_key: :ci_ref_id, inverse_of: :pipelines

    has_internal_id :iid, scope: :project, presence: false,
      track_if: -> { !importing? },
      ensure_if: -> { !importing? },
      init: ->(pipeline, scope) do
        if pipeline
          pipeline.project&.all_pipelines&.maximum(:iid) || pipeline.project&.all_pipelines&.count
        elsif scope
          ::Ci::Pipeline.where(**scope).maximum(:iid)
        end
      end

    has_many :stages, -> { order(position: :asc) }, inverse_of: :pipeline
    has_many :statuses, class_name: 'CommitStatus', foreign_key: :commit_id, inverse_of: :pipeline
    has_many :latest_statuses_ordered_by_stage, -> { latest.order(:stage_idx, :stage) }, class_name: 'CommitStatus', foreign_key: :commit_id, inverse_of: :pipeline
    has_many :latest_statuses, -> { latest }, class_name: 'CommitStatus', foreign_key: :commit_id, inverse_of: :pipeline
    has_many :processables, class_name: 'Ci::Processable', foreign_key: :commit_id, inverse_of: :pipeline
    has_many :bridges, class_name: 'Ci::Bridge', foreign_key: :commit_id, inverse_of: :pipeline
    has_many :builds, foreign_key: :commit_id, inverse_of: :pipeline
    has_many :job_artifacts, through: :builds
    has_many :trigger_requests, dependent: :destroy, foreign_key: :commit_id # rubocop:disable Cop/ActiveRecordDependent
    has_many :variables, class_name: 'Ci::PipelineVariable'
    has_many :deployments, through: :builds
    has_many :environments, -> { distinct }, through: :deployments
    has_many :latest_builds, -> { latest.with_project_and_metadata }, foreign_key: :commit_id, inverse_of: :pipeline, class_name: 'Ci::Build'
    has_many :downloadable_artifacts, -> do
      not_expired.or(where_exists(::Ci::Pipeline.artifacts_locked.where('ci_pipelines.id = ci_builds.commit_id'))).downloadable.with_job
    end, through: :latest_builds, source: :job_artifacts

    has_many :messages, class_name: 'Ci::PipelineMessage', inverse_of: :pipeline

    # Merge requests for which the current pipeline is running against
    # the merge request's latest commit.
    has_many :merge_requests_as_head_pipeline, foreign_key: "head_pipeline_id", class_name: 'MergeRequest'

    has_many :pending_builds, -> { pending }, foreign_key: :commit_id, class_name: 'Ci::Build', inverse_of: :pipeline
    has_many :failed_builds, -> { latest.failed }, foreign_key: :commit_id, class_name: 'Ci::Build', inverse_of: :pipeline
    has_many :retryable_builds, -> { latest.failed_or_canceled.includes(:project) }, foreign_key: :commit_id, class_name: 'Ci::Build', inverse_of: :pipeline
    has_many :cancelable_statuses, -> { cancelable }, foreign_key: :commit_id, class_name: 'CommitStatus'
    has_many :manual_actions, -> { latest.manual_actions.includes(:project) }, foreign_key: :commit_id, class_name: 'Ci::Build', inverse_of: :pipeline
    has_many :scheduled_actions, -> { latest.scheduled_actions.includes(:project) }, foreign_key: :commit_id, class_name: 'Ci::Build', inverse_of: :pipeline

    has_many :auto_canceled_pipelines, class_name: 'Ci::Pipeline', foreign_key: 'auto_canceled_by_id'
    has_many :auto_canceled_jobs, class_name: 'CommitStatus', foreign_key: 'auto_canceled_by_id'
    has_many :sourced_pipelines, class_name: 'Ci::Sources::Pipeline', foreign_key: :source_pipeline_id

    has_one :source_pipeline, class_name: 'Ci::Sources::Pipeline', inverse_of: :pipeline

    has_one :chat_data, class_name: 'Ci::PipelineChatData'

    has_many :triggered_pipelines, through: :sourced_pipelines, source: :pipeline
    has_many :child_pipelines, -> { merge(Ci::Sources::Pipeline.same_project) }, through: :sourced_pipelines, source: :pipeline
    has_one :triggered_by_pipeline, through: :source_pipeline, source: :source_pipeline
    has_one :parent_pipeline, -> { merge(Ci::Sources::Pipeline.same_project) }, through: :source_pipeline, source: :source_pipeline
    has_one :source_job, through: :source_pipeline, source: :source_job
    has_one :source_bridge, through: :source_pipeline, source: :source_bridge

    has_one :pipeline_config, class_name: 'Ci::PipelineConfig', inverse_of: :pipeline

    has_many :daily_build_group_report_results, class_name: 'Ci::DailyBuildGroupReportResult', foreign_key: :last_pipeline_id
    has_many :latest_builds_report_results, through: :latest_builds, source: :report_results
    has_many :pipeline_artifacts, class_name: 'Ci::PipelineArtifact', inverse_of: :pipeline, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent

    accepts_nested_attributes_for :variables, reject_if: :persisted?

    delegate :full_path, to: :project, prefix: true

    validates :sha, presence: { unless: :importing? }
    validates :ref, presence: { unless: :importing? }
    validates :tag, inclusion: { in: [false], if: :merge_request? }

    validates :external_pull_request, presence: { if: :external_pull_request_event? }
    validates :external_pull_request, absence: { unless: :external_pull_request_event? }
    validates :tag, inclusion: { in: [false], if: :external_pull_request_event? }

    validates :status, presence: { unless: :importing? }
    validate :valid_commit_sha, unless: :importing?
    validates :source, exclusion: { in: %w(unknown), unless: :importing? }, on: :create

    after_create :keep_around_commits, unless: :importing?

    use_fast_destroy :job_artifacts

    # We use `Enums::Ci::Pipeline.sources` here so that EE can more easily extend
    # this `Hash` with new values.
    enum_with_nil source: Enums::Ci::Pipeline.sources

    enum_with_nil config_source: Enums::Ci::Pipeline.config_sources

    # We use `Enums::Ci::Pipeline.failure_reasons` here so that EE can more easily
    # extend this `Hash` with new values.
    enum failure_reason: Enums::Ci::Pipeline.failure_reasons

    enum locked: { unlocked: 0, artifacts_locked: 1 }

    state_machine :status, initial: :created do
      event :enqueue do
        transition [:created, :manual, :waiting_for_resource, :preparing, :skipped, :scheduled] => :pending
        transition [:success, :failed, :canceled] => :running

        # this is needed to ensure tests to be covered
        transition [:running] => :running
      end

      event :request_resource do
        transition any - [:waiting_for_resource] => :waiting_for_resource
      end

      event :prepare do
        transition any - [:preparing] => :preparing
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

      event :delay do
        transition any - [:scheduled] => :scheduled
      end

      # IMPORTANT
      # Do not add any operations to this state_machine
      # Create a separate worker for each new operation

      before_transition [:created, :waiting_for_resource, :preparing, :pending] => :running do |pipeline|
        pipeline.started_at = Time.current
      end

      before_transition any => [:success, :failed, :canceled] do |pipeline|
        pipeline.finished_at = Time.current
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

      after_transition [:created, :waiting_for_resource, :preparing, :pending] => :running do |pipeline|
        pipeline.run_after_commit { PipelineMetricsWorker.perform_async(pipeline.id) }
      end

      after_transition any => [:success] do |pipeline|
        pipeline.run_after_commit { PipelineMetricsWorker.perform_async(pipeline.id) }
      end

      after_transition [:created, :waiting_for_resource, :preparing, :pending, :running] => :success do |pipeline|
        # We wait a little bit to ensure that all BuildFinishedWorkers finish first
        # because this is where some metrics like code coverage is parsed and stored
        # in CI build records which the daily build metrics worker relies on.
        pipeline.run_after_commit { Ci::DailyBuildGroupReportResultsWorker.perform_in(10.minutes, pipeline.id) }
      end

      after_transition do |pipeline, transition|
        next if transition.loopback?

        pipeline.run_after_commit do
          PipelineHooksWorker.perform_async(pipeline.id)
          ExpirePipelineCacheWorker.perform_async(pipeline.id)
        end
      end

      after_transition any => ::Ci::Pipeline.completed_statuses do |pipeline|
        pipeline.run_after_commit do
          pipeline.persistent_ref.delete

          pipeline.all_merge_requests.each do |merge_request|
            next unless merge_request.auto_merge_enabled?

            AutoMergeProcessWorker.perform_async(merge_request.id)
          end

          if pipeline.auto_devops_source?
            self.class.auto_devops_pipelines_completed_total.increment(status: pipeline.status)
          end
        end
      end

      after_transition any => ::Ci::Pipeline.completed_statuses do |pipeline|
        pipeline.run_after_commit do
          ::Ci::PipelineArtifacts::CoverageReportWorker.perform_async(pipeline.id)
          ::Ci::PipelineArtifacts::CreateQualityReportWorker.perform_async(pipeline.id)
        end
      end

      after_transition any => ::Ci::Pipeline.completed_statuses do |pipeline|
        next unless pipeline.bridge_waiting?

        pipeline.run_after_commit do
          ::Ci::PipelineBridgeStatusWorker.perform_async(pipeline.id)
        end
      end

      after_transition any => any do |pipeline|
        pipeline.run_after_commit do
          # Passing the seq-id ensures this is idempotent
          seq_id = ::Atlassian::JiraConnect::Client.generate_update_sequence_id
          ::JiraConnect::SyncBuildsWorker.perform_async(pipeline.id, seq_id)
        end
      end

      after_transition any => ::Ci::Pipeline.completed_statuses do |pipeline|
        pipeline.run_after_commit do
          ::Ci::TestFailureHistoryService.new(pipeline).async.perform_if_needed # rubocop: disable CodeReuse/ServiceClass
        end
      end

      after_transition any => [:success, :failed] do |pipeline|
        ref_status = pipeline.ci_ref&.update_status_by!(pipeline)

        pipeline.run_after_commit do
          PipelineNotificationWorker.perform_async(pipeline.id, ref_status: ref_status)
        end
      end

      after_transition any => [:failed] do |pipeline|
        pipeline.run_after_commit do
          ::Gitlab::Ci::Pipeline::Metrics.pipeline_failure_reason_counter.increment(reason: pipeline.failure_reason)

          AutoDevops::DisableWorker.perform_async(pipeline.id) if pipeline.auto_devops_source?
        end
      end
    end

    scope :internal, -> { where(source: internal_sources) }
    scope :no_child, -> { where.not(source: :parent_pipeline) }
    scope :ci_sources, -> { where(source: Enums::Ci::Pipeline.ci_sources.values) }
    scope :ci_branch_sources, -> { where(source: Enums::Ci::Pipeline.ci_branch_sources.values) }
    scope :ci_and_parent_sources, -> { where(source: Enums::Ci::Pipeline.ci_and_parent_sources.values) }
    scope :for_user, -> (user) { where(user: user) }
    scope :for_sha, -> (sha) { where(sha: sha) }
    scope :for_source_sha, -> (source_sha) { where(source_sha: source_sha) }
    scope :for_sha_or_source_sha, -> (sha) { for_sha(sha).or(for_source_sha(sha)) }
    scope :for_ref, -> (ref) { where(ref: ref) }
    scope :for_branch, -> (branch) { for_ref(branch).where(tag: false) }
    scope :for_id, -> (id) { where(id: id) }
    scope :for_iid, -> (iid) { where(iid: iid) }
    scope :for_project, -> (project_id) { where(project_id: project_id) }
    scope :created_after, -> (time) { where('ci_pipelines.created_at > ?', time) }
    scope :created_before_id, -> (id) { where('ci_pipelines.id < ?', id) }
    scope :before_pipeline, -> (pipeline) { created_before_id(pipeline.id).outside_pipeline_family(pipeline) }
    scope :eager_load_project, -> { eager_load(project: [:route, { namespace: :route }]) }

    scope :outside_pipeline_family, ->(pipeline) do
      where.not(id: pipeline.same_family_pipeline_ids)
    end

    scope :with_reports, -> (reports_scope) do
      where('EXISTS (?)', ::Ci::Build.latest.with_reports(reports_scope).where('ci_pipelines.id=ci_builds.commit_id').select(1))
    end

    scope :with_only_interruptible_builds, -> do
      where('NOT EXISTS (?)',
        Ci::Build.where('ci_builds.commit_id = ci_pipelines.id')
                 .with_status(:running, :success, :failed)
                 .not_interruptible
      )
    end

    # Returns the pipelines that associated with the given merge request.
    # In general, please use `Ci::PipelinesForMergeRequestFinder` instead,
    # for checking permission of the actor.
    scope :triggered_by_merge_request, -> (merge_request) do
      where(source: :merge_request_event,
            merge_request: merge_request,
            project: [merge_request.source_project, merge_request.target_project])
    end

    # Returns the pipelines in descending order (= newest first), optionally
    # limited to a number of references.
    #
    # ref - The name (or names) of the branch(es)/tag(s) to limit the list of
    #       pipelines to.
    # sha - The commit SHA (or mutliple SHAs) to limit the list of pipelines to.
    # limit - This limits a backlog search, default to 100.
    def self.newest_first(ref: nil, sha: nil, limit: 100)
      relation = order(id: :desc)
      relation = relation.where(ref: ref) if ref
      relation = relation.where(sha: sha) if sha

      if limit
        ids = relation.limit(limit).select(:id)
        relation = relation.where(id: ids)
      end

      relation
    end

    def self.latest_status(ref = nil)
      newest_first(ref: ref).pluck(:status).first
    end

    def self.latest_successful_for_ref(ref)
      newest_first(ref: ref).success.take
    end

    def self.latest_successful_for_sha(sha)
      newest_first(sha: sha).success.take
    end

    def self.latest_successful_for_refs(refs)
      relation = newest_first(ref: refs).success

      relation.each_with_object({}) do |pipeline, hash|
        hash[pipeline.ref] ||= pipeline
      end
    end

    def self.latest_running_for_ref(ref)
      newest_first(ref: ref).running.take
    end

    def self.latest_failed_for_ref(ref)
      newest_first(ref: ref).failed.take
    end

    # Returns a Hash containing the latest pipeline for every given
    # commit.
    #
    # The keys of this Hash are the commit SHAs, the values the pipelines.
    #
    # commits - The list of commit SHAs to get the pipelines for.
    # ref - The ref to scope the data to (e.g. "master"). If the ref is not
    #       given we simply get the latest pipelines for the commits, regardless
    #       of what refs the pipelines belong to.
    def self.latest_pipeline_per_commit(commits, ref = nil)
      sql = select('DISTINCT ON (sha) *')
              .where(sha: commits)
              .order(:sha, id: :desc)

      sql = sql.where(ref: ref) if ref

      sql.each_with_object({}) do |pipeline, hash|
        hash[pipeline.sha] = pipeline
      end
    end

    def self.latest_successful_ids_per_project
      success.group(:project_id).select('max(id) as id')
    end

    def self.last_finished_for_ref_id(ci_ref_id)
      where(ci_ref_id: ci_ref_id).ci_sources.finished.order(id: :desc).select(:id).take
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

    def self.bridgeable_statuses
      ::Ci::Pipeline::AVAILABLE_STATUSES - %w[created waiting_for_resource preparing pending]
    end

    def self.auto_devops_pipelines_completed_total
      @auto_devops_pipelines_completed_total ||= Gitlab::Metrics.counter(:auto_devops_pipelines_completed_total, 'Number of completed auto devops pipelines')
    end

    def uses_needs?
      builds.where(scheduling_type: :dag).any?
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
      stage unless stage.statuses_count == 0
    end

    def ref_exists?
      project.repository.ref_exists?(git_ref)
    rescue Gitlab::Git::Repository::NoRepository
      false
    end

    def legacy_stages_using_composite_status
      stages = latest_statuses_ordered_by_stage.group_by(&:stage)

      stages.map do |stage_name, jobs|
        composite_status = Gitlab::Ci::Status::Composite
          .new(jobs)

        Ci::LegacyStage.new(self,
          name: stage_name,
          status: composite_status.status,
          warnings: composite_status.warnings?)
      end
    end

    def triggered_pipelines_with_preloads
      triggered_pipelines.preload(:source_job)
    end

    # TODO: Remove usage of this method in templates
    def legacy_stages
      legacy_stages_using_composite_status
    end

    def valid_commit_sha
      if self.sha == Gitlab::Git::BLANK_SHA
        self.errors.add(:sha, " cant be 00000000 (branch removal)")
      end
    end

    def git_author_name
      strong_memoize(:git_author_name) do
        commit.try(:author_name)
      end
    end

    def git_author_email
      strong_memoize(:git_author_email) do
        commit.try(:author_email)
      end
    end

    def git_author_full_text
      strong_memoize(:git_author_full_text) do
        commit.try(:author_full_text)
      end
    end

    def git_commit_message
      strong_memoize(:git_commit_message) do
        commit.try(:message)
      end
    end

    def git_commit_title
      strong_memoize(:git_commit_title) do
        commit.try(:title)
      end
    end

    def git_commit_full_title
      strong_memoize(:git_commit_full_title) do
        commit.try(:full_title)
      end
    end

    def git_commit_description
      strong_memoize(:git_commit_description) do
        commit.try(:description)
      end
    end

    def git_commit_timestamp
      strong_memoize(:git_commit_timestamp) do
        commit.try(:timestamp)
      end
    end

    def before_sha
      super || Gitlab::Git::BLANK_SHA
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

    def cancel_running(retries: 1)
      commit_status_relations = [:project, :pipeline]
      ci_build_relations = [:deployment, :taggings]

      retry_lock(cancelable_statuses, retries, name: 'ci_pipeline_cancel_running') do |cancelables|
        cancelables.find_in_batches do |batch|
          ActiveRecord::Associations::Preloader.new.preload(batch, commit_status_relations)
          ActiveRecord::Associations::Preloader.new.preload(batch.select { |job| job.is_a?(Ci::Build) }, ci_build_relations)

          batch.each do |job|
            yield(job) if block_given?
            job.cancel
          end
        end
      end
    end

    def auto_cancel_running(pipeline, retries: 1)
      update(auto_canceled_by: pipeline)

      cancel_running(retries: retries) do |job|
        job.auto_canceled_by = pipeline
      end
    end

    # rubocop: disable CodeReuse/ServiceClass
    def retry_failed(current_user)
      Ci::RetryPipelineService.new(project, current_user)
        .execute(self)
    end
    # rubocop: enable CodeReuse/ServiceClass

    def lazy_ref_commit
      BatchLoader.for(ref).batch do |refs, loader|
        next unless project.repository_exists?

        project.repository.list_commits_by_ref_name(refs).then do |commits|
          commits.each { |key, commit| loader.call(key, commits[key]) }
        end
      end
    end

    def latest?
      return false unless git_ref && commit.present?
      return false if lazy_ref_commit.nil?

      lazy_ref_commit.id == commit.id
    end

    def retried
      @retried ||= (statuses.order(id: :desc) - latest_statuses)
    end

    def coverage
      coverage_array = latest_statuses.map(&:coverage).compact
      if coverage_array.size >= 1
        '%.2f' % (coverage_array.reduce(:+) / coverage_array.size)
      end
    end

    def update_builds_coverage
      builds.with_coverage_regex.without_coverage.each(&:update_coverage)
    end

    def batch_lookup_report_artifact_for_file_type(file_type)
      latest_report_artifacts
        .values_at(*::Ci::JobArtifact.associated_file_types_for(file_type.to_s))
        .flatten
        .compact
        .last
    end

    # This batch loads the latest reports for each CI job artifact
    # type (e.g. sast, dast, etc.) in a single SQL query to eliminate
    # the need to do N different `job_artifacts.where(file_type:
    # X).last` calls.
    #
    # Return a hash of file type => array of 1 job artifact
    def latest_report_artifacts
      ::Gitlab::SafeRequestStore.fetch("pipeline:#{self.id}:latest_report_artifacts") do
        ::Ci::JobArtifact.where(
          id: job_artifacts.with_reports
            .select('max(ci_job_artifacts.id) as id')
            .group(:file_type)
        )
          .preload(:job)
          .group_by(&:file_type)
      end
    end

    def has_kubernetes_active?
      strong_memoize(:has_kubernetes_active) do
        project.deployment_platform&.active?
      end
    end

    def freeze_period?
      Ci::FreezePeriodStatus.new(project: project).execute
    end

    def has_warnings?
      number_of_warnings > 0
    end

    def number_of_warnings
      BatchLoader.for(id).batch(default_value: 0) do |pipeline_ids, loader|
        ::CommitStatus.where(commit_id: pipeline_ids)
          .latest
          .failed_but_allowed
          .group(:commit_id)
          .count
          .each { |id, amount| loader.call(id, amount) }
      end
    end

    def needs_processing?
      statuses
        .where(processed: [false, nil])
        .latest
        .exists?
    end

    def has_yaml_errors?
      yaml_errors.present?
    end

    def add_error_message(content)
      add_message(:error, content)
    end

    def add_warning_message(content)
      add_message(:warning, content)
    end

    # We can't use `messages.error` scope here because messages should also be
    # read when the pipeline is not persisted. Using the scope will return no
    # results as it would query persisted data.
    def error_messages
      messages.select(&:error?)
    end

    def warning_messages(limit: nil)
      messages.select(&:warning?).tap do |warnings|
        break warnings.take(limit) if limit
      end
    end

    # Manually set the notes for a Ci::Pipeline
    # There is no ActiveRecord relation between Ci::Pipeline and notes
    # as they are related to a commit sha. This method helps importing
    # them using the +Gitlab::ImportExport::Project::RelationFactory+ class.
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

    def set_status(new_status)
      retry_optimistic_lock(self, name: 'ci_pipeline_set_status') do
        case new_status
        when 'created' then nil
        when 'waiting_for_resource' then request_resource
        when 'preparing' then prepare
        when 'pending' then enqueue
        when 'running' then run
        when 'success' then succeed
        when 'failed' then drop
        when 'canceled' then cancel
        when 'skipped' then skip
        when 'manual' then block
        when 'scheduled' then delay
        else
          raise Ci::HasStatus::UnknownStatusError,
                "Unknown status `#{new_status}`"
        end
      end
    end

    def protected_ref?
      strong_memoize(:protected_ref) { project.protected_for?(git_ref) }
    end

    def legacy_trigger
      strong_memoize(:legacy_trigger) { trigger_requests.first }
    end

    def persisted_variables
      Gitlab::Ci::Variables::Collection.new.tap do |variables|
        break variables unless persisted?

        variables.append(key: 'CI_PIPELINE_ID', value: id.to_s)
        variables.append(key: 'CI_PIPELINE_URL', value: Gitlab::Routing.url_helpers.project_pipeline_url(project, self))
      end
    end

    def predefined_variables
      Gitlab::Ci::Variables::Collection.new.tap do |variables|
        variables.append(key: 'CI_PIPELINE_IID', value: iid.to_s)
        variables.append(key: 'CI_PIPELINE_SOURCE', value: source.to_s)
        variables.append(key: 'CI_PIPELINE_CREATED_AT', value: created_at&.iso8601)

        variables.concat(predefined_commit_variables)

        if merge_request?
          variables.append(key: 'CI_MERGE_REQUEST_EVENT_TYPE', value: merge_request_event_type.to_s)
          variables.append(key: 'CI_MERGE_REQUEST_SOURCE_BRANCH_SHA', value: source_sha.to_s)
          variables.append(key: 'CI_MERGE_REQUEST_TARGET_BRANCH_SHA', value: target_sha.to_s)

          diff = self.merge_request_diff
          if diff.present?
            variables.append(key: 'CI_MERGE_REQUEST_DIFF_ID', value: diff.id.to_s)
            variables.append(key: 'CI_MERGE_REQUEST_DIFF_BASE_SHA', value: diff.base_commit_sha)
          end

          variables.concat(merge_request.predefined_variables)
        end

        if open_merge_requests_refs.any?
          variables.append(key: 'CI_OPEN_MERGE_REQUESTS', value: open_merge_requests_refs.join(','))
        end

        variables.append(key: 'CI_KUBERNETES_ACTIVE', value: 'true') if has_kubernetes_active?
        variables.append(key: 'CI_DEPLOY_FREEZE', value: 'true') if freeze_period?

        if external_pull_request_event? && external_pull_request
          variables.concat(external_pull_request.predefined_variables)
        end
      end
    end

    def predefined_commit_variables
      Gitlab::Ci::Variables::Collection.new.tap do |variables|
        variables.append(key: 'CI_COMMIT_SHA', value: sha)
        variables.append(key: 'CI_COMMIT_SHORT_SHA', value: short_sha)
        variables.append(key: 'CI_COMMIT_BEFORE_SHA', value: before_sha)
        variables.append(key: 'CI_COMMIT_REF_NAME', value: source_ref)
        variables.append(key: 'CI_COMMIT_REF_SLUG', value: source_ref_slug)
        variables.append(key: 'CI_COMMIT_BRANCH', value: ref) if branch?
        variables.append(key: 'CI_COMMIT_TAG', value: ref) if tag?
        variables.append(key: 'CI_COMMIT_MESSAGE', value: git_commit_message.to_s)
        variables.append(key: 'CI_COMMIT_TITLE', value: git_commit_full_title.to_s)
        variables.append(key: 'CI_COMMIT_DESCRIPTION', value: git_commit_description.to_s)
        variables.append(key: 'CI_COMMIT_REF_PROTECTED', value: (!!protected_ref?).to_s)
        variables.append(key: 'CI_COMMIT_TIMESTAMP', value: git_commit_timestamp.to_s)
        variables.append(key: 'CI_COMMIT_AUTHOR', value: git_author_full_text.to_s)

        # legacy variables
        variables.append(key: 'CI_BUILD_REF', value: sha)
        variables.append(key: 'CI_BUILD_BEFORE_SHA', value: before_sha)
        variables.append(key: 'CI_BUILD_REF_NAME', value: source_ref)
        variables.append(key: 'CI_BUILD_REF_SLUG', value: source_ref_slug)
        variables.append(key: 'CI_BUILD_TAG', value: ref) if tag?
      end
    end

    def queued_duration
      return unless started_at

      seconds = (started_at - created_at).to_i
      seconds unless seconds == 0
    end

    def update_duration
      return unless started_at

      self.duration = Gitlab::Ci::Pipeline::Duration.from_pipeline(self)
    end

    def execute_hooks
      project.execute_hooks(pipeline_data, :pipeline_hooks) if project.has_active_hooks?(:pipeline_hooks)
      project.execute_integrations(pipeline_data, :pipeline_hooks) if project.has_active_integrations?(:pipeline_hooks)
    end

    # All the merge requests for which the current pipeline runs/ran against
    def all_merge_requests
      @all_merge_requests ||=
        if merge_request?
          MergeRequest.where(id: merge_request_id)
        else
          MergeRequest.where(source_project_id: project_id, source_branch: ref)
            .by_commit_sha(sha)
        end
    end

    def all_merge_requests_by_recency
      all_merge_requests.order(id: :desc)
    end

    # This returns a list of MRs that point
    # to the same source project/branch
    def related_merge_requests
      if merge_request?
        # We look for all other MRs that this branch might be pointing to
        MergeRequest.where(
          source_project_id: merge_request.source_project_id,
          source_branch: merge_request.source_branch)
      else
        MergeRequest.where(
          source_project_id: project_id,
          source_branch: ref)
      end
    end

    # We cannot use `all_merge_requests`, due to race condition
    # This returns a list of at most 4 open MRs
    def open_merge_requests_refs
      strong_memoize(:open_merge_requests_refs) do
        # We ensure that triggering user can actually read the pipeline
        related_merge_requests
          .opened
          .limit(MAX_OPEN_MERGE_REQUESTS_REFS)
          .order(id: :desc)
          .preload(:target_project)
          .select { |mr| can?(user, :read_merge_request, mr) }
          .map { |mr| mr.to_reference(project, full: true) }
      end
    end

    def same_family_pipeline_ids
      ::Gitlab::Ci::PipelineObjectHierarchy.new(
        self.class.default_scoped.where(id: root_ancestor), options: { project_condition: :same }
      ).base_and_descendants.select(:id)
    end

    def build_with_artifacts_in_self_and_descendants(name)
      builds_in_self_and_descendants
        .ordered_by_pipeline # find job in hierarchical order
        .with_downloadable_artifacts
        .find_by_name(name)
    end

    def builds_in_self_and_descendants
      Ci::Build.latest.where(pipeline: self_and_descendants)
    end

    def environments_in_self_and_descendants
      environment_ids = self_and_descendants.joins(:deployments).select(:'deployments.environment_id')

      Environment.where(id: environment_ids)
    end

    # With multi-project and parent-child pipelines
    def self_and_upstreams
      object_hierarchy.base_and_ancestors
    end

    # With multi-project and parent-child pipelines
    def self_with_upstreams_and_downstreams
      object_hierarchy.all_objects
    end

    # With only parent-child pipelines
    def self_and_ancestors
      object_hierarchy(project_condition: :same).base_and_ancestors
    end

    # With only parent-child pipelines
    def self_and_descendants
      object_hierarchy(project_condition: :same).base_and_descendants
    end

    def root_ancestor
      return self unless child?

      object_hierarchy(project_condition: :same)
        .base_and_ancestors(hierarchy_order: :desc)
        .first
    end

    def bridge_triggered?
      source_bridge.present?
    end

    def bridge_waiting?
      source_bridge&.dependent?
    end

    def child?
      parent_pipeline? && # child pipelines have `parent_pipeline` source
        parent_pipeline.present?
    end

    def parent?
      child_pipelines.exists?
    end

    def created_successfully?
      persisted? && failure_reason.blank?
    end

    def detailed_status(current_user)
      Gitlab::Ci::Status::Pipeline::Factory
        .new(self.present, current_user)
        .fabricate!
    end

    def find_job_with_archive_artifacts(name)
      builds.latest.with_downloadable_artifacts.find_by_name(name)
    end

    def latest_builds_with_artifacts
      # We purposely cast the builds to an Array here. Because we always use the
      # rows if there are more than 0 this prevents us from having to run two
      # queries: one to get the count and one to get the rows.
      @latest_builds_with_artifacts ||= builds.latest.with_artifacts_not_expired.to_a
    end

    def latest_report_builds(reports_scope = ::Ci::JobArtifact.with_reports)
      builds.latest.with_reports(reports_scope)
    end

    def latest_test_report_builds
      latest_report_builds(Ci::JobArtifact.test_reports).preload(:project)
    end

    def builds_with_coverage
      builds.latest.with_coverage
    end

    def builds_with_failed_tests(limit: nil)
      latest_test_report_builds.failed.limit(limit)
    end

    def has_reports?(reports_scope)
      complete? && latest_report_builds(reports_scope).exists?
    end

    def has_coverage_reports?
      pipeline_artifacts&.report_exists?(:code_coverage)
    end

    def can_generate_coverage_reports?
      has_reports?(Ci::JobArtifact.coverage_reports)
    end

    def has_codequality_mr_diff_report?
      pipeline_artifacts&.report_exists?(:code_quality_mr_diff)
    end

    def can_generate_codequality_reports?
      has_reports?(Ci::JobArtifact.codequality_reports)
    end

    def test_report_summary
      strong_memoize(:test_report_summary) do
        Gitlab::Ci::Reports::TestReportSummary.new(latest_builds_report_results)
      end
    end

    def test_reports
      Gitlab::Ci::Reports::TestReports.new.tap do |test_reports|
        latest_test_report_builds.find_each do |build|
          build.collect_test_reports!(test_reports)
        end
      end
    end

    def accessibility_reports
      Gitlab::Ci::Reports::AccessibilityReports.new.tap do |accessibility_reports|
        latest_report_builds(Ci::JobArtifact.accessibility_reports).each do |build|
          build.collect_accessibility_reports!(accessibility_reports)
        end
      end
    end

    def coverage_reports
      Gitlab::Ci::Reports::CoverageReports.new.tap do |coverage_reports|
        latest_report_builds(Ci::JobArtifact.coverage_reports).includes(:project).find_each do |build|
          build.collect_coverage_reports!(coverage_reports)
        end
      end
    end

    def codequality_reports
      Gitlab::Ci::Reports::CodequalityReports.new.tap do |codequality_reports|
        latest_report_builds(Ci::JobArtifact.codequality_reports).each do |build|
          build.collect_codequality_reports!(codequality_reports)
        end
      end
    end

    def terraform_reports
      ::Gitlab::Ci::Reports::TerraformReports.new.tap do |terraform_reports|
        latest_report_builds(::Ci::JobArtifact.terraform_reports).each do |build|
          build.collect_terraform_reports!(terraform_reports)
        end
      end
    end

    def has_archive_artifacts?
      complete? && builds.latest.with_existing_job_artifacts(Ci::JobArtifact.archive.or(Ci::JobArtifact.metadata)).exists?
    end

    def has_exposed_artifacts?
      complete? && builds.latest.with_exposed_artifacts.exists?
    end

    def branch_updated?
      strong_memoize(:branch_updated) do
        push_details.branch_updated?
      end
    end

    # Returns the modified paths.
    #
    # The returned value is
    # * Array: List of modified paths that should be evaluated
    # * nil: Modified path can not be evaluated
    def modified_paths
      strong_memoize(:modified_paths) do
        if merge_request?
          merge_request.modified_paths
        elsif branch_updated?
          push_details.modified_paths
        elsif external_pull_request? && ::Feature.enabled?(:ci_modified_paths_of_external_prs, project, default_enabled: :yaml)
          external_pull_request.modified_paths
        end
      end
    end

    def all_worktree_paths
      strong_memoize(:all_worktree_paths) do
        project.repository.ls_files(sha)
      end
    end

    def top_level_worktree_paths
      strong_memoize(:top_level_worktree_paths) do
        project.repository.tree(sha).blobs.map(&:path)
      end
    end

    def default_branch?
      ref == project.default_branch
    end

    def merge_request?
      merge_request_id.present?
    end

    def external_pull_request?
      external_pull_request_id.present?
    end

    def detached_merge_request_pipeline?
      merge_request? && target_sha.nil?
    end

    def legacy_detached_merge_request_pipeline?
      detached_merge_request_pipeline? && !merge_request_ref?
    end

    def merged_result_pipeline?
      merge_request? && target_sha.present?
    end

    def merge_request_ref?
      MergeRequest.merge_request_ref?(ref)
    end

    def matches_sha_or_source_sha?(sha)
      self.sha == sha || self.source_sha == sha
    end

    def triggered_by?(current_user)
      user == current_user
    end

    def source_ref
      if merge_request?
        merge_request.source_branch
      else
        ref
      end
    end

    def source_ref_slug
      Gitlab::Utils.slugify(source_ref.to_s)
    end

    def find_stage_by_name!(name)
      stages.find_by!(name: name)
    end

    def full_error_messages
      errors ? errors.full_messages.to_sentence : ""
    end

    def merge_request_event_type
      return unless merge_request?

      strong_memoize(:merge_request_event_type) do
        if merged_result_pipeline?
          :merged_result
        elsif detached_merge_request_pipeline?
          :detached
        end
      end
    end

    def persistent_ref
      @persistent_ref ||= PersistentRef.new(pipeline: self)
    end

    def dangling?
      Enums::Ci::Pipeline.dangling_sources.key?(source.to_sym)
    end

    def source_ref_path
      if branch? || merge_request?
        Gitlab::Git::BRANCH_REF_PREFIX + source_ref.to_s
      elsif tag?
        Gitlab::Git::TAG_REF_PREFIX + source_ref.to_s
      end
    end

    # Set scheduling type of processables if they were created before scheduling_type
    # data was deployed (https://gitlab.com/gitlab-org/gitlab/-/merge_requests/22246).
    def ensure_scheduling_type!
      processables.populate_scheduling_type!
    end

    def ensure_ci_ref!
      self.ci_ref = Ci::Ref.ensure_for(self)
    end

    # We need `base_and_ancestors` in a specific order to "break" when needed.
    # If we use `find_each`, then the order is broken.
    # rubocop:disable Rails/FindEach
    def reset_source_bridge!(current_user)
      if ::Feature.enabled?(:ci_reset_bridge_with_subsequent_jobs, project, default_enabled: :yaml)
        return unless bridge_waiting?

        source_bridge.pending!
        Ci::AfterRequeueJobService.new(project, current_user).execute(source_bridge) # rubocop:disable CodeReuse/ServiceClass
      else
        self_and_upstreams.includes(:source_bridge).each do |pipeline|
          break unless pipeline.bridge_waiting?

          pipeline.source_bridge.pending!
        end
      end
    end
    # rubocop:enable Rails/FindEach

    # EE-only
    def merge_train_pipeline?
      false
    end

    def security_reports(report_types: [])
      reports_scope = report_types.empty? ? ::Ci::JobArtifact.security_reports : ::Ci::JobArtifact.security_reports(file_types: report_types)

      ::Gitlab::Ci::Reports::Security::Reports.new(self).tap do |security_reports|
        latest_report_builds(reports_scope).each do |build|
          build.collect_security_reports!(security_reports)
        end
      end
    end

    def build_matchers
      self.builds.latest.build_matchers(project)
    end

    private

    def add_message(severity, content)
      messages.build(severity: severity, content: content)
    end

    def pipeline_data
      strong_memoize(:pipeline_data) do
        Gitlab::DataBuilder::Pipeline.build(self)
      end
    end

    def merge_request_diff_sha
      return unless merge_request?

      if merged_result_pipeline?
        source_sha
      else
        sha
      end
    end

    def merge_request_diff
      return unless merge_request?

      merge_request.merge_request_diff_for(merge_request_diff_sha)
    end

    def push_details
      strong_memoize(:push_details) do
        Gitlab::Git::Push.new(project, before_sha, sha, git_ref)
      end
    end

    def git_ref
      strong_memoize(:git_ref) do
        if merge_request?
          ##
          # In the future, we're going to change this ref to
          # merge request's merged reference, such as "refs/merge-requests/:iid/merge".
          # In order to do that, we have to update GitLab-Runner's source pulling
          # logic.
          # See https://gitlab.com/gitlab-org/gitlab-runner/merge_requests/1092
          Gitlab::Git::BRANCH_REF_PREFIX + ref.to_s
        else
          super
        end
      end
    end

    def keep_around_commits
      return unless project

      project.repository.keep_around(self.sha, self.before_sha)
    end

    # Without using `unscoped`, caller scope is also included into the query.
    # Using `unscoped` here will be redundant after Rails 6.1
    def object_hierarchy(options = {})
      ::Gitlab::Ci::PipelineObjectHierarchy
        .new(self.class.unscoped.where(id: id), options: options)
    end
  end
end

Ci::Pipeline.prepend_mod_with('Ci::Pipeline')
