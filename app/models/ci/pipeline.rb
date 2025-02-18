# frozen_string_literal: true

module Ci
  class Pipeline < Ci::ApplicationRecord
    include Ci::Partitionable
    include Ci::HasStatus
    include Ci::HasCompletionReason
    include Importable
    include AfterCommitQueue
    include Presentable
    include Gitlab::Allowable
    include Gitlab::OptimisticLocking
    include Gitlab::Utils::StrongMemoize
    include AtomicInternalId
    include Ci::HasRef
    include ShaAttribute
    include FromUnion
    include UpdatedAtFilterable
    include EachBatch
    include FastDestroyAll::Helpers

    self.table_name = :p_ci_pipelines
    self.primary_key = :id
    self.sequence_name = :ci_pipelines_id_seq

    MAX_OPEN_MERGE_REQUESTS_REFS = 4

    PROJECT_ROUTE_AND_NAMESPACE_ROUTE = {
      project: [:project_feature, :route, { namespace: :route }]
    }.freeze

    DEFAULT_CONFIG_PATH = '.gitlab-ci.yml'

    CANCELABLE_STATUSES = (Ci::HasStatus::CANCELABLE_STATUSES + ['manual']).freeze
    UNLOCKABLE_STATUSES = (Ci::Pipeline.completed_statuses + [:manual]).freeze
    # UI only shows 100+. TODO: pass constant to UI for SSoT
    COUNT_FAILED_JOBS_LIMIT = 101

    paginates_per 15

    sha_attribute :source_sha
    sha_attribute :target_sha
    query_constraints :id, :partition_id
    partitionable scope: ->(_) { Ci::Pipeline.current_partition_value }, partitioned: true

    # Ci::CreatePipelineService returns Ci::Pipeline so this is the only place
    # where we can pass additional information from the service. This accessor
    # is used for storing the processed metadata for linting purposes.
    # There is an open issue to address this:
    # https://gitlab.com/gitlab-org/gitlab/-/issues/259010
    attr_accessor :config_metadata

    # This is used to retain access to the method defined by `Ci::HasRef`
    # before being overridden in this class.
    alias_method :jobs_git_ref, :git_ref

    belongs_to :project, inverse_of: :all_pipelines
    belongs_to :project_mirror, primary_key: :project_id, foreign_key: :project_id, inverse_of: :pipelines
    belongs_to :user
    belongs_to :auto_canceled_by, class_name: 'Ci::Pipeline', inverse_of: :auto_canceled_pipelines
    belongs_to :pipeline_schedule, class_name: 'Ci::PipelineSchedule'
    belongs_to :merge_request, class_name: 'MergeRequest'
    belongs_to :external_pull_request, class_name: 'Ci::ExternalPullRequest'
    belongs_to :ci_ref, class_name: 'Ci::Ref', foreign_key: :ci_ref_id, inverse_of: :pipelines
    belongs_to :trigger, class_name: 'Ci::Trigger', inverse_of: :pipelines

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

    has_many :stages, ->(pipeline) { in_partition(pipeline).order(position: :asc) },
      partition_foreign_key: :partition_id, inverse_of: :pipeline

    #
    # In https://gitlab.com/groups/gitlab-org/-/epics/9991, we aim to convert all CommitStatus related models to
    # Ci::Job models. With that epic, we aim to replace `statuses` with `jobs`.
    #
    # DEPRECATED:
    has_many :statuses, ->(pipeline) { in_partition(pipeline) }, class_name: 'CommitStatus', foreign_key: :commit_id, inverse_of: :pipeline, partition_foreign_key: :partition_id
    has_many :processables, ->(pipeline) { in_partition(pipeline) }, class_name: 'Ci::Processable', foreign_key: :commit_id, inverse_of: :pipeline, partition_foreign_key: :partition_id
    has_many :latest_statuses_ordered_by_stage, ->(pipeline) { latest.in_partition(pipeline).order(:stage_idx, :stage) }, class_name: 'CommitStatus', foreign_key: :commit_id, inverse_of: :pipeline, partition_foreign_key: :partition_id
    has_many :latest_statuses, ->(pipeline) { latest.in_partition(pipeline) }, class_name: 'CommitStatus', foreign_key: :commit_id, inverse_of: :pipeline, partition_foreign_key: :partition_id
    has_many :statuses_order_id_desc, ->(pipeline) { in_partition(pipeline).order_id_desc }, class_name: 'CommitStatus', foreign_key: :commit_id,
      inverse_of: :pipeline, partition_foreign_key: :partition_id
    has_many :bridges, ->(pipeline) { in_partition(pipeline) }, class_name: 'Ci::Bridge', foreign_key: :commit_id, inverse_of: :pipeline, partition_foreign_key: :partition_id
    has_many :builds, ->(pipeline) { in_partition(pipeline) }, foreign_key: :commit_id, inverse_of: :pipeline, partition_foreign_key: :partition_id
    has_many :build_execution_configs, ->(pipeline) { in_partition(pipeline) }, class_name: 'Ci::BuildExecutionConfig', inverse_of: :pipeline, partition_foreign_key: :partition_id
    has_many :generic_commit_statuses, ->(pipeline) { in_partition(pipeline) }, foreign_key: :commit_id, inverse_of: :pipeline, class_name: 'GenericCommitStatus', partition_foreign_key: :partition_id
    #
    # NEW:
    has_many :all_jobs, ->(pipeline) { in_partition(pipeline) }, class_name: 'CommitStatus', foreign_key: :commit_id, inverse_of: :pipeline, partition_foreign_key: :partition_id
    has_many :current_jobs, ->(pipeline) { latest.in_partition(pipeline) }, class_name: 'CommitStatus', foreign_key: :commit_id, inverse_of: :pipeline, partition_foreign_key: :partition_id
    has_many :all_processable_jobs, ->(pipeline) { in_partition(pipeline) }, class_name: 'Ci::Processable', foreign_key: :commit_id, inverse_of: :pipeline, partition_foreign_key: :partition_id
    has_many :current_processable_jobs, ->(pipeline) { latest.in_partition(pipeline) }, class_name: 'Ci::Processable', foreign_key: :commit_id, inverse_of: :pipeline, partition_foreign_key: :partition_id

    has_many :job_artifacts, through: :builds
    has_many :build_trace_chunks, class_name: 'Ci::BuildTraceChunk', through: :builds, source: :trace_chunks
    has_many :trigger_requests, dependent: :destroy, foreign_key: :commit_id, inverse_of: :pipeline # rubocop:disable Cop/ActiveRecordDependent
    has_many :variables, ->(pipeline) { in_partition(pipeline) }, class_name: 'Ci::PipelineVariable', inverse_of: :pipeline, partition_foreign_key: :partition_id
    has_many :latest_builds, ->(pipeline) { in_partition(pipeline).latest.with_project_and_metadata }, foreign_key: :commit_id, inverse_of: :pipeline, class_name: 'Ci::Build'
    has_many :downloadable_artifacts, -> do
      not_expired.or(where_exists(Ci::Pipeline.artifacts_locked.where("#{Ci::Pipeline.quoted_table_name}.id = #{Ci::Build.quoted_table_name}.commit_id"))).downloadable.with_job
    end, through: :latest_builds, source: :job_artifacts
    has_many :latest_successful_jobs, ->(pipeline) { in_partition(pipeline).latest.success.with_project_and_metadata }, foreign_key: :commit_id, inverse_of: :pipeline, class_name: 'Ci::Processable'
    has_many :latest_finished_jobs, ->(pipeline) { in_partition(pipeline).latest.finished.with_project_and_metadata }, foreign_key: :commit_id, inverse_of: :pipeline, class_name: 'Ci::Processable'

    has_many :messages, class_name: 'Ci::PipelineMessage', inverse_of: :pipeline

    # Merge requests for which the current pipeline is running against
    # the merge request's latest commit.
    has_many :merge_requests_as_head_pipeline, foreign_key: :head_pipeline_id, class_name: 'MergeRequest',
      inverse_of: :head_pipeline

    has_many :pending_builds, ->(pipeline) { in_partition(pipeline).pending }, foreign_key: :commit_id, class_name: 'Ci::Build', inverse_of: :pipeline
    has_many :failed_builds, ->(pipeline) { in_partition(pipeline).latest.failed }, foreign_key: :commit_id, class_name: 'Ci::Build',
      inverse_of: :pipeline
    has_many :limited_failed_builds, ->(pipeline) { in_partition(pipeline).latest.failed.limit(COUNT_FAILED_JOBS_LIMIT) }, foreign_key: :commit_id, class_name: 'Ci::Build',
      inverse_of: :pipeline
    has_many :retryable_builds, ->(pipeline) { in_partition(pipeline).latest.failed_or_canceled.includes(:project) }, foreign_key: :commit_id, class_name: 'Ci::Build', inverse_of: :pipeline
    has_many :cancelable_statuses, ->(pipeline) { in_partition(pipeline).cancelable }, foreign_key: :commit_id, class_name: 'CommitStatus',
      inverse_of: :pipeline
    has_many :manual_actions, ->(pipeline) { in_partition(pipeline).latest.manual_actions.includes(:project) }, foreign_key: :commit_id, class_name: 'Ci::Processable', inverse_of: :pipeline
    has_many :scheduled_actions, ->(pipeline) { in_partition(pipeline).latest.scheduled_actions.includes(:project) }, foreign_key: :commit_id, class_name: 'Ci::Build', inverse_of: :pipeline

    has_many :auto_canceled_pipelines, class_name: 'Ci::Pipeline', foreign_key: :auto_canceled_by_id,
      inverse_of: :auto_canceled_by
    has_many :auto_canceled_jobs, class_name: 'CommitStatus', foreign_key: :auto_canceled_by_id,
      inverse_of: :auto_canceled_by
    has_many :sourced_pipelines, class_name: 'Ci::Sources::Pipeline', foreign_key: :source_pipeline_id,
      inverse_of: :source_pipeline

    has_one :source_pipeline, class_name: 'Ci::Sources::Pipeline', inverse_of: :pipeline

    has_one :chat_data, class_name: 'Ci::PipelineChatData'

    has_many :triggered_pipelines, through: :sourced_pipelines, source: :pipeline
    # Only includes direct and not nested children
    has_many :child_pipelines, -> { merge(Ci::Sources::Pipeline.same_project) }, through: :sourced_pipelines, source: :pipeline
    has_one :triggered_by_pipeline, through: :source_pipeline, source: :source_pipeline
    has_one :parent_pipeline, -> { merge(Ci::Sources::Pipeline.same_project) }, through: :source_pipeline, source: :source_pipeline
    has_one :source_job, through: :source_pipeline, source: :source_job
    has_one :source_bridge, through: :source_pipeline, source: :source_bridge

    has_one :pipeline_config, class_name: 'Ci::PipelineConfig', inverse_of: :pipeline

    has_one :pipeline_metadata, class_name: 'Ci::PipelineMetadata', inverse_of: :pipeline

    has_many :daily_build_group_report_results, class_name: 'Ci::DailyBuildGroupReportResult',
      foreign_key: :last_pipeline_id, inverse_of: :last_pipeline

    has_many :latest_builds_report_results, through: :latest_builds, source: :report_results
    has_many :pipeline_artifacts, class_name: 'Ci::PipelineArtifact', inverse_of: :pipeline, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent

    accepts_nested_attributes_for :variables, reject_if: :persisted?

    delegate :full_path, to: :project, prefix: true
    delegate :name, to: :pipeline_metadata, allow_nil: true

    validates :sha, presence: { unless: :importing? }
    validates :ref, presence: { unless: :importing? }
    validates :tag, inclusion: { in: [false], if: :merge_request? }

    validates :external_pull_request, presence: { if: :external_pull_request_event? }
    validates :external_pull_request, absence: { unless: :external_pull_request_event? }
    validates :tag, inclusion: { in: [false], if: :external_pull_request_event? }

    validates :status, presence: { unless: :importing? }
    validate :valid_commit_sha, unless: :importing?
    validates :source, exclusion: { in: %w[unknown], unless: :importing? }, on: :create
    validates :project, presence: true

    after_create :keep_around_commits, unless: :importing?
    after_commit :track_ci_pipeline_created_event, on: :create, if: :internal_pipeline?
    after_find :observe_age_in_minutes, unless: :importing?

    use_fast_destroy :job_artifacts
    use_fast_destroy :build_trace_chunks

    # We use `Enums::Ci::Pipeline.sources` here so that EE can more easily extend
    # this `Hash` with new values.
    enum source: Enums::Ci::Pipeline.sources

    enum config_source: Enums::Ci::Pipeline.config_sources

    # We use `Enums::Ci::Pipeline.failure_reasons` here so that EE can more easily
    # extend this `Hash` with new values.
    enum failure_reason: Enums::Ci::Pipeline.failure_reasons

    enum locked: { unlocked: 0, artifacts_locked: 1 }

    state_machine :status, initial: :created do
      event :enqueue do
        transition [:created, :manual, :waiting_for_resource, :preparing, :skipped, :scheduled] => :pending
        transition [:success, :failed, :canceling, :canceled] => :running

        # this is needed to ensure tests to be covered
        transition [:running] => :running
        transition [:waiting_for_callback] => :waiting_for_callback
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

      event :wait_for_callback do
        transition any - [:waiting_for_callback] => :waiting_for_callback
      end

      event :skip do
        transition any - [:skipped] => :skipped
      end

      event :drop do
        transition any - [:failed] => :failed
      end

      event :succeed do
        # A success pipeline can also be retried, for example; a pipeline with a failed manual job.
        # When retrying the pipeline, the status of the pipeline is not changed because the failed
        # manual job transitions to the `manual` status.
        # More info: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/98967#note_1144718316
        transition any => :success
      end

      event :start_cancel do
        transition any - [:canceling, :canceled] => :canceling
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
        pipeline.started_at ||= Time.current
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

      after_transition any => UNLOCKABLE_STATUSES do |pipeline|
        pipeline.run_after_commit do
          Ci::PipelineFinishedWorker.perform_async(pipeline.id)
          Ci::Refs::UnlockPreviousPipelinesWorker.perform_async(pipeline.ci_ref_id)
        end
      end

      after_transition [:created, :waiting_for_resource, :preparing, :pending, :running] => :success do |pipeline|
        # We wait a little bit to ensure that all Ci::BuildFinishedWorkers finish first
        # because this is where some metrics like code coverage is parsed and stored
        # in CI build records which the daily build metrics worker relies on.
        pipeline.run_after_commit { Ci::DailyBuildGroupReportResultsWorker.perform_in(10.minutes, pipeline.id) }
      end

      after_transition do |pipeline, transition|
        next if transition.loopback?

        pipeline.run_after_commit do
          unless pipeline.user&.blocked?
            Gitlab::AppLogger.info(
              message: "Enqueuing hooks for Pipeline #{pipeline.id}: #{pipeline.status}",
              class: self.class.name,
              pipeline_id: pipeline.id,
              project_id: pipeline.project_id,
              pipeline_status: pipeline.status)

            PipelineHooksWorker.perform_async(pipeline.id)
          end

          if pipeline.project.jira_subscription_exists?
            # Passing the seq-id ensures this is idempotent
            seq_id = ::Atlassian::JiraConnect::Client.generate_update_sequence_id
            ::JiraConnect::SyncBuildsWorker.perform_async(pipeline.id, seq_id)
          end

          Ci::ExpirePipelineCacheService.new.execute(pipeline) # rubocop: disable CodeReuse/ServiceClass
        end
      end

      after_transition any => ::Ci::Pipeline.completed_statuses do |pipeline|
        pipeline.run_after_commit do
          AutoMergeProcessWorker.perform_async({ 'pipeline_id' => self.id })

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

      after_transition any => ::Ci::Pipeline.completed_statuses do |pipeline|
        pipeline.run_after_commit do
          ::Ci::TestFailureHistoryService.new(pipeline).async.perform_if_needed # rubocop: disable CodeReuse/ServiceClass
        end
      end

      after_transition any => ::Ci::Pipeline.completed_statuses do |pipeline|
        pipeline.run_after_commit do
          ::Ci::JobArtifacts::TrackArtifactReportWorker.perform_async(pipeline.id)
        end
      end

      # This needs to be kept in sync with `Ci::PipelineRef#should_delete?`
      after_transition any => ::Ci::Pipeline.stopped_statuses do |pipeline|
        pipeline.run_after_commit do
          if Feature.enabled?(:pipeline_delete_gitaly_refs_in_batches, pipeline.project)
            pipeline.persistent_ref.async_delete
          elsif Feature.enabled?(:pipeline_cleanup_ref_worker_async, pipeline.project)
            ::Ci::PipelineCleanupRefWorker.perform_async(pipeline.id)
          else
            pipeline.persistent_ref.delete
          end
        end
      end

      after_transition any => [:success, :failed] do |pipeline|
        ref_status = pipeline.ci_ref&.update_status_by!(pipeline)

        pipeline.run_after_commit do
          # We don't send notifications for a pipeline dropped due to the
          # user been blocked.
          unless pipeline.user&.blocked?
            PipelineNotificationWorker
              .perform_async(pipeline.id, 'ref_status' => ref_status&.to_s)
          end
        end
      end

      after_transition any => [:failed] do |pipeline|
        pipeline.run_after_commit do
          ::Gitlab::Ci::Pipeline::Metrics.pipeline_failure_reason_counter.increment(reason: pipeline.failure_reason)

          AutoDevops::DisableWorker.perform_async(pipeline.id) if pipeline.auto_devops_source?
        end
      end

      after_transition any => [:running, *::Ci::Pipeline.completed_statuses] do |pipeline|
        project = pipeline&.project

        next unless project

        pipeline.run_after_commit do
          next if pipeline.child?

          pipeline.all_merge_requests.opened.each do |merge_request|
            GraphqlTriggers.merge_request_merge_status_updated(merge_request)
          end
        end
      end
    end

    scope :with_unlockable_status, -> { with_status(*UNLOCKABLE_STATUSES) }
    scope :internal, -> { where(source: internal_sources) }
    scope :no_tag, -> { where(tag: false) }
    scope :no_child, -> { where.not(source: :parent_pipeline) }
    scope :ci_sources, -> { where(source: Enums::Ci::Pipeline.ci_sources.values) }
    scope :ci_branch_sources, -> { where(source: Enums::Ci::Pipeline.ci_branch_sources.values) }
    scope :ci_and_parent_sources, -> { where(source: Enums::Ci::Pipeline.ci_and_parent_sources.values) }
    scope :ci_and_security_orchestration_sources, -> do
      where(source: Enums::Ci::Pipeline.ci_and_security_orchestration_sources.values)
    end

    scope :for_user, ->(user) { where(user: user) }
    scope :for_sha, ->(sha) { where(sha: sha) }
    scope :where_not_sha, ->(sha) { where.not(sha: sha) }
    scope :for_source_sha, ->(source_sha) { where(source_sha: source_sha) }
    scope :for_sha_or_source_sha, ->(sha) { for_sha(sha).or(for_source_sha(sha)) }
    scope :for_ref, ->(ref) { where(ref: ref) }
    scope :for_branch, ->(branch) { for_ref(branch).where(tag: false) }
    scope :for_iid, ->(iid) { where(iid: iid) }
    scope :for_project, ->(project_id) { where(project_id: project_id) }
    scope :for_name, ->(name) do
      name_column = Ci::PipelineMetadata.arel_table[:name]

      joins(:pipeline_metadata).where(name_column.eq(name))
    end
    scope :for_status, ->(status) { where(status: status) }
    scope :created_after, ->(time) { where(arel_table[:created_at].gt(time)) }
    scope :created_before, ->(time) { where(arel_table[:created_at].lt(time)) }
    scope :created_before_id, ->(id) { where(arel_table[:id].lt(id)) }
    scope :before_pipeline, ->(pipeline) { created_before_id(pipeline.id).outside_pipeline_family(pipeline) }
    scope :with_pipeline_source, ->(source) { where(source: source) }
    scope :preload_pipeline_metadata, -> { preload(:pipeline_metadata) }

    scope :outside_pipeline_family, ->(pipeline) do
      where.not(id: pipeline.same_family_pipeline_ids)
    end

    scope :with_reports, ->(reports_scope) do
      where_exists(Ci::Build.latest.scoped_pipeline.with_artifacts(reports_scope))
    end

    scope :conservative_interruptible, -> do
      where_not_exists(
        Ci::Build.scoped_pipeline.with_status(STARTED_STATUSES).not_interruptible
      )
    end

    # Returns the pipelines that associated with the given merge request.
    # In general, please use `Ci::PipelinesForMergeRequestFinder` instead,
    # for checking permission of the actor.
    scope :triggered_by_merge_request, ->(merge_request) do
      where(
        source: :merge_request_event,
        merge_request: merge_request,
        project: [merge_request.source_project, merge_request.target_project]
      )
    end

    scope :order_id_asc, -> { order(id: :asc) }
    scope :order_id_desc, -> { order(id: :desc) }

    # Returns the pipelines in descending order (= newest first), optionally
    # limited to a number of references.
    #
    # ref - The name (or names) of the branch(es)/tag(s) to limit the list of
    #       pipelines to.
    # sha - The commit SHA (or multiple SHAs) to limit the list of pipelines to.
    # limit - Number of pipelines to return. Chaining with sampling methods (#pick, #take)
    #         will cause unnecessary subqueries.
    def self.newest_first(ref: nil, sha: nil, limit: nil)
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
      newest_first(ref: ref).pick(:status)
    end

    def self.latest_successful_for_ref(ref)
      newest_first(ref: ref).success.take
    end

    def self.latest_successful_for_sha(sha)
      newest_first(sha: sha).success.take
    end

    def self.latest_successful_for_refs(refs)
      return Ci::Pipeline.none if refs.empty?

      refs_values = refs.map { |ref| "(#{connection.quote(ref)})" }.join(",")
      query = Arel.sql(sanitize_sql_array(["refs_values.ref = #{quoted_table_name}.ref"]))
      join_query = success.where(query).order(id: :desc).limit(1)

      Ci::Pipeline
        .from("(VALUES #{refs_values}) refs_values (ref)")
        .joins("INNER JOIN LATERAL (#{join_query.to_sql}) #{quoted_table_name} ON TRUE")
        .index_by(&:ref)
    end

    def self.latest_running_for_ref(ref)
      newest_first(ref: ref).running.take
    end

    def self.latest_failed_for_ref(ref)
      newest_first(ref: ref).failed.take
    end

    def self.jobs_count_in_alive_pipelines
      created_after(24.hours.ago).alive.joins(:statuses).count
    end

    def self.builds_count_in_alive_pipelines
      created_after(24.hours.ago).alive.joins(:builds).count
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

      sql.index_by(&:sha)
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
      ::Ci::Pipeline::AVAILABLE_STATUSES - %w[created waiting_for_resource waiting_for_callback preparing pending]
    end

    def self.auto_devops_pipelines_completed_total
      @auto_devops_pipelines_completed_total ||= Gitlab::Metrics.counter(:auto_devops_pipelines_completed_total, 'Number of completed auto devops pipelines')
    end

    def self.current_partition_value
      Gitlab::SafeRequestStore.fetch(:ci_current_partition_value) do
        Ci::Partition.current&.id || Ci::Partition::INITIAL_PARTITION_VALUE
      end
    end

    def self.object_hierarchy(relation, options = {})
      ::Gitlab::Ci::PipelineObjectHierarchy.new(relation, options: options)
    end

    def self.internal_id_scope_usage
      :ci_pipelines
    end

    def uses_needs?
      processables.where(scheduling_type: :dag).any?
    end

    def stages_count
      stages.count
    end

    def total_size
      statuses.count(:id)
    end

    def tags_count
      Ci::BuildTag.in_partition(self).where(build: builds).count
    end

    def distinct_tags_count
      Ci::BuildTag.in_partition(self).where(build: builds).count('distinct(tag_id)')
    end

    def stages_names
      stages.order(:position).pluck(:name)
    end

    def ref_exists?
      project.repository.ref_exists?(git_ref)
    rescue Gitlab::Git::Repository::NoRepository
      false
    end

    def triggered_pipelines_with_preloads
      triggered_pipelines.preload(:source_job)
    end

    def valid_commit_sha
      self.errors.add(:sha, "can't be 00000000 (branch removal)") if Gitlab::Git.blank_ref?(self.sha)
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
      super || project.repository.blank_ref
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
      cancelable_statuses.any? && internal_pipeline?
    end

    def auto_canceled?
      canceled? && auto_canceled_by_id?
    end

    # rubocop: disable CodeReuse/ServiceClass
    def retry_failed(current_user)
      Ci::RetryPipelineService.new(project, current_user)
        .execute(self)
    end
    # rubocop: enable CodeReuse/ServiceClass

    def lazy_ref_commit
      BatchLoader.for(ref).batch(key: project.id) do |refs, loader|
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
      coverage_array.sum / coverage_array.size if coverage_array.size >= 1
    end

    def update_builds_coverage
      builds.with_coverage_regex.without_coverage.each(&:update_coverage)
    end

    def batch_lookup_report_artifact_for_file_type(file_type)
      batch_lookup_report_artifact_for_file_types([file_type])
    end

    def batch_lookup_report_artifact_for_file_types(file_types)
      file_types_to_search = []
      file_types.each { |file_type| file_types_to_search.append(*::Ci::JobArtifact.associated_file_types_for(file_type.to_s)) }

      latest_report_artifacts
        .values_at(*file_types_to_search.uniq)
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
          id: job_artifacts.all_reports
            .select("max(#{Ci::JobArtifact.quoted_table_name}.id) as id")
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
      strong_memoize(:freeze_period) do
        project.freeze_periods.any?(&:active?)
      end
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

    # Like #drop!, but does not persist the pipeline nor trigger any state
    # machine callbacks.
    def set_failed(failure_reason)
      self.failure_reason = failure_reason.to_s
      self.status = 'failed'
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
    def notes=(notes_to_save)
      notes_to_save.reject! do |note_to_save|
        notes.any? do |note|
          [note_to_save.note, note_to_save.created_at.to_i] == [note.note, note.created_at.to_i]
        end
      end

      notes_to_save.each do |note|
        note[:id] = nil
        note[:commit_id] = sha
        note[:noteable_id] = self['id']
        note.save!
      end
    end

    def notes
      project.notes.for_commit_id(sha)
    end

    # rubocop: disable Metrics/CyclomaticComplexity -- breaking apart hurts readability
    def set_status(new_status)
      retry_optimistic_lock(self, name: 'ci_pipeline_set_status') do
        case new_status
        when 'created' then nil
        when 'waiting_for_resource' then request_resource
        when 'preparing' then prepare
        when 'waiting_for_callback' then wait_for_callback
        when 'pending' then enqueue
        when 'running' then run
        when 'success' then succeed
        when 'failed' then drop
        when 'canceling' then start_cancel
        when 'canceled' then cancel
        when 'skipped' then skip
        when 'manual' then block
        when 'scheduled' then delay
        else
          raise Ci::HasStatus::UnknownStatusError, "Unknown status `#{new_status}`"
        end
      end
    end
    # rubocop: enable Metrics/CyclomaticComplexity

    def protected_ref?
      strong_memoize(:protected_ref) { project.protected_for?(git_ref) }
    end

    def legacy_trigger
      strong_memoize(:legacy_trigger) { trigger_requests.first }
    end

    def variables_builder
      @variables_builder ||= ::Gitlab::Ci::Variables::Builder.new(self)
    end

    def persisted_variables
      Gitlab::Ci::Variables::Collection.new.tap do |variables|
        break variables unless persisted?

        variables.append(key: 'CI_PIPELINE_ID', value: id.to_s)
        variables.append(key: 'CI_PIPELINE_URL', value: Gitlab::Routing.url_helpers.project_pipeline_url(project, self))
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

    def build_with_artifacts_in_self_and_project_descendants(name)
      builds_in_self_and_project_descendants
        .ordered_by_pipeline # find job in hierarchical order
        .with_downloadable_artifacts
        .find_by_name(name)
    end

    def builds_in_self_and_project_descendants
      Ci::Build.in_partition(self).latest.where(pipeline: self_and_project_descendants)
    end

    def bridges_in_self_and_project_descendants
      Ci::Bridge.in_partition(self).latest.where(pipeline: self_and_project_descendants)
    end

    def jobs_in_self_and_project_descendants
      Ci::Processable.in_partition(self).latest.where(pipeline: self_and_project_descendants)
    end

    def environments_in_self_and_project_descendants(deployment_status: nil)
      # We limit to 100 unique environments for application safety.
      # See: https://gitlab.com/gitlab-org/gitlab/-/issues/340781#note_699114700
      expanded_environment_names =
        jobs_in_self_and_project_descendants.joins(:metadata)
                                      .where.not(Ci::BuildMetadata.table_name => { expanded_environment_name: nil })
                                      .distinct("#{Ci::BuildMetadata.quoted_table_name}.expanded_environment_name")
                                      .limit(100)
                                      .pluck(:expanded_environment_name)

      Environment.where(project: project, name: expanded_environment_names).with_deployment(sha, status: deployment_status)
    end

    # With multi-project and parent-child pipelines
    def self_and_upstreams
      object_hierarchy.base_and_ancestors
    end

    # With multi-project and parent-child pipelines
    def self_and_downstreams
      object_hierarchy.base_and_descendants
    end

    # With multi-project and parent-child pipelines
    def upstream_and_all_downstreams
      object_hierarchy.all_objects
    end

    # With only parent-child pipelines
    def self_and_project_ancestors
      object_hierarchy(project_condition: :same).base_and_ancestors
    end

    # With only parent-child pipelines
    def self_and_project_descendants
      object_hierarchy(project_condition: :same).base_and_descendants
    end

    # With only parent-child pipelines
    def all_child_pipelines
      object_hierarchy(project_condition: :same).descendants
    end

    def self_and_project_descendants_complete?
      self_and_project_descendants.all?(&:complete?)
    end

    # Follow the parent-child relationships and return the top-level parent
    def root_ancestor
      return self unless child?

      object_hierarchy(project_condition: :same)
        .base_and_ancestors(hierarchy_order: :desc)
        .first
    end

    # Follow the upstream pipeline relationships, regardless of multi-project or
    # parent-child, and return the top-level ancestor.
    def upstream_root
      @upstream_root ||= object_hierarchy.base_and_ancestors(hierarchy_order: :desc).first
    end

    # Applies to all parent-child and multi-project pipelines
    def complete_hierarchy_count
      upstream_root.self_and_downstreams.count
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

    def filtered_as_empty?
      filtered_by_rules? || filtered_by_workflow_rules?
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

    def latest_report_builds(reports_scope = ::Ci::JobArtifact.all_reports)
      builds.latest.with_artifacts(reports_scope)
    end

    def latest_test_report_builds
      latest_report_builds(Ci::JobArtifact.of_report_type(:test)).preload(:project, :metadata, job_artifacts: :artifact_report)
    end

    def latest_report_builds_in_self_and_project_descendants(reports_scope = ::Ci::JobArtifact.all_reports)
      builds_in_self_and_project_descendants.with_artifacts(reports_scope)
    end

    def builds_with_coverage
      builds.latest.with_coverage
    end

    def builds_with_failed_tests(limit: nil)
      latest_test_report_builds.failed.limit(limit)
    end

    def has_reports?(reports_scope)
      latest_report_builds(reports_scope).exists?
    end

    def complete_and_has_reports?(reports_scope)
      if Feature.enabled?(:mr_show_reports_immediately, project, type: :development)
        latest_report_builds(reports_scope).exists?
      else
        complete? && has_reports?(reports_scope)
      end
    end

    def complete_or_manual_and_has_reports?(reports_scope)
      if Feature.enabled?(:mr_show_reports_immediately, project, type: :development)
        latest_report_builds(reports_scope).exists?
      else
        complete_or_manual? && has_reports?(reports_scope)
      end
    end

    def has_coverage_reports?
      pipeline_artifacts&.report_exists?(:code_coverage)
    end

    def has_codequality_mr_diff_report?
      pipeline_artifacts&.report_exists?(:code_quality_mr_diff)
    end

    def can_generate_codequality_reports?
      complete_and_has_reports?(Ci::JobArtifact.of_report_type(:codequality))
    end

    def test_report_summary
      strong_memoize(:test_report_summary) do
        Gitlab::Ci::Reports::TestReportSummary.new(latest_builds_report_results)
      end
    end

    def test_reports
      Gitlab::Ci::Reports::TestReport.new.tap do |test_reports|
        latest_test_report_builds.find_each do |build|
          build.collect_test_reports!(test_reports)
        end
      end
    end

    def accessibility_reports
      Gitlab::Ci::Reports::AccessibilityReports.new.tap do |accessibility_reports|
        latest_report_builds(Ci::JobArtifact.of_report_type(:accessibility)).each do |build|
          build.collect_accessibility_reports!(accessibility_reports)
        end
      end
    end

    def codequality_reports
      Gitlab::Ci::Reports::CodequalityReports.new.tap do |codequality_reports|
        latest_report_builds(Ci::JobArtifact.of_report_type(:codequality)).each do |build|
          build.collect_codequality_reports!(codequality_reports)
        end
      end
    end

    def terraform_reports
      ::Gitlab::Ci::Reports::TerraformReports.new.tap do |terraform_reports|
        latest_report_builds(::Ci::JobArtifact.of_report_type(:terraform)).each do |build|
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

    def has_erasable_artifacts?
      complete? && builds.latest.with_erasable_artifacts.exists?
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
        elsif external_pull_request?
          external_pull_request.modified_paths
        end
      end
    end

    def modified_paths_since(compare_to_sha)
      strong_memoize_with(:modified_paths_since, compare_to_sha) do
        project.repository.diff_stats(project.repository.merge_base(compare_to_sha, sha), sha).paths
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
      merge_request_id.present? && merge_request.present?
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

    def tag_pipeline?
      tag?
    end

    def type
      if merge_train_pipeline?
        'merge_train'
      elsif merged_result_pipeline?
        'merged_result'
      elsif merge_request?
        'merge_request'
      elsif tag_pipeline?
        'tag'
      else
        'branch'
      end
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

    def stage(name)
      stages.find_by(name: name)
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

    def ensure_persistent_ref
      return if persistent_ref.exist?

      persistent_ref.create
    end

    # For dependent bridge jobs we reset the upstream bridge recursively
    # to reflect that a downstream pipeline is running again
    def reset_source_bridge!(current_user)
      # break recursion when no source_pipeline bridge (first upstream pipeline)
      return unless bridge_waiting?
      return unless current_user.can?(:update_pipeline, source_bridge.pipeline)

      Ci::EnqueueJobService.new(source_bridge, current_user: current_user).execute(&:pending!) # rubocop:disable CodeReuse/ServiceClass
    end

    # EE-only
    def merge_train_pipeline?
      false
    end

    def build_matchers
      self.builds.latest.build_matchers(project)
    end

    def cluster_agent_authorizations
      strong_memoize(:cluster_agent_authorizations) do
        ::Clusters::Agents::Authorizations::CiAccess::Finder.new(project).execute
      end
    end

    def has_test_reports?
      strong_memoize(:has_test_reports) do
        has_reports?(::Ci::JobArtifact.of_report_type(:test))
      end
    end

    def age_in_minutes
      return 0 unless persisted?

      raise ArgumentError, 'pipeline not fully loaded' unless has_attribute?(:created_at)

      return 0 unless created_at

      (Time.current - created_at).ceil / 60
    end

    def merge_request_diff
      return unless merge_request?

      merge_request.merge_request_diff_for(merge_request_diff_sha)
    end

    def auto_cancel_on_job_failure
      pipeline_metadata&.auto_cancel_on_job_failure || 'none'
    end

    def auto_cancel_on_new_commit
      pipeline_metadata&.auto_cancel_on_new_commit || 'conservative'
    end

    def cancel_async_on_job_failure
      case auto_cancel_on_job_failure
      when 'none'
        # no-op
      when 'all'
        ::Ci::UserCancelPipelineWorker.perform_async(id, id, user.id)
      else
        raise ArgumentError,
          "Unknown auto_cancel_on_job_failure value: #{auto_cancel_on_job_failure}"
      end
    end

    private

    def add_message(severity, content)
      messages.build(severity: severity, content: content, project_id: project_id)
    end

    def merge_request_diff_sha
      return unless merge_request?

      if merged_result_pipeline?
        source_sha
      else
        sha
      end
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

      project.repository.keep_around(self.sha, self.before_sha, source: self.class.name)
    end

    def observe_age_in_minutes
      return unless age_metric_enabled?
      return unless persisted? && has_attribute?(:created_at)

      ::Gitlab::Ci::Pipeline::Metrics
        .pipeline_age_histogram
        .observe({}, age_in_minutes)
    end

    def age_metric_enabled?
      ::Gitlab::SafeRequestStore.fetch(:age_metric_enabled) do
        ::Feature.enabled?(:ci_pipeline_age_histogram, type: :ops)
      end
    end

    # Without using `unscoped`, caller scope is also included into the query.
    # Using `unscoped` here will be redundant after Rails 6.1
    def object_hierarchy(options = {})
      ::Gitlab::Ci::PipelineObjectHierarchy
        .new(self.class.unscoped.where(id: id), options: options)
    end

    def internal_pipeline?
      source != "external"
    end

    def track_ci_pipeline_created_event
      Gitlab::InternalEvents.track_event(
        'create_ci_internal_pipeline',
        project: project,
        user: user,
        additional_properties: {
          label: source,
          property: config_source
        }
      )
    end
  end
end

Ci::Pipeline.prepend_mod_with('Ci::Pipeline')
