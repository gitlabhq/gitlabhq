# frozen_string_literal: true

module Ci
  class Build < Ci::Processable
    include Ci::Metadatable
    include Ci::Contextable
    include TokenAuthenticatable
    include AfterCommitQueue
    include ObjectStorage::BackgroundMove
    include Presentable
    include Importable
    include Ci::HasRef
    include IgnorableColumns

    BuildArchivedError = Class.new(StandardError)

    belongs_to :project, inverse_of: :builds
    belongs_to :runner
    belongs_to :trigger_request
    belongs_to :erased_by, class_name: 'User'
    belongs_to :pipeline, class_name: 'Ci::Pipeline', foreign_key: :commit_id

    RUNNER_FEATURES = {
      upload_multiple_artifacts: -> (build) { build.publishes_artifacts_reports? },
      refspecs: -> (build) { build.merge_request_ref? },
      artifacts_exclude: -> (build) { build.supports_artifacts_exclude? },
      multi_build_steps: -> (build) { build.multi_build_steps? },
      return_exit_code: -> (build) { build.exit_codes_defined? }
    }.freeze

    DEFAULT_RETRIES = {
      scheduler_failure: 2
    }.freeze

    DEGRADATION_THRESHOLD_VARIABLE_NAME = 'DEGRADATION_THRESHOLD'
    RUNNERS_STATUS_CACHE_EXPIRATION = 1.minute

    has_one :deployment, as: :deployable, class_name: 'Deployment'
    has_one :pending_state, class_name: 'Ci::BuildPendingState', inverse_of: :build
    has_one :queuing_entry, class_name: 'Ci::PendingBuild', foreign_key: :build_id
    has_one :runtime_metadata, class_name: 'Ci::RunningBuild', foreign_key: :build_id
    has_many :trace_sections, class_name: 'Ci::BuildTraceSection'
    has_many :trace_chunks, class_name: 'Ci::BuildTraceChunk', foreign_key: :build_id, inverse_of: :build
    has_many :report_results, class_name: 'Ci::BuildReportResult', inverse_of: :build

    has_many :job_artifacts, class_name: 'Ci::JobArtifact', foreign_key: :job_id, dependent: :destroy, inverse_of: :job # rubocop:disable Cop/ActiveRecordDependent
    has_many :job_variables, class_name: 'Ci::JobVariable', foreign_key: :job_id
    has_many :sourced_pipelines, class_name: 'Ci::Sources::Pipeline', foreign_key: :source_job_id

    has_many :pages_deployments, inverse_of: :ci_build

    Ci::JobArtifact.file_types.each do |key, value|
      has_one :"job_artifacts_#{key}", -> { where(file_type: value) }, class_name: 'Ci::JobArtifact', inverse_of: :job, foreign_key: :job_id
    end

    has_one :runner_session, class_name: 'Ci::BuildRunnerSession', validate: true, inverse_of: :build

    accepts_nested_attributes_for :runner_session, update_only: true
    accepts_nested_attributes_for :job_variables

    delegate :url, to: :runner_session, prefix: true, allow_nil: true
    delegate :terminal_specification, to: :runner_session, allow_nil: true
    delegate :service_specification, to: :runner_session, allow_nil: true
    delegate :gitlab_deploy_token, to: :project
    delegate :trigger_short_token, to: :trigger_request, allow_nil: true

    ignore_columns :id_convert_to_bigint, remove_with: '14.1', remove_after: '2021-07-22'
    ignore_columns :stage_id_convert_to_bigint, remove_with: '14.1', remove_after: '2021-07-22'

    ##
    # Since Gitlab 11.5, deployments records started being created right after
    # `ci_builds` creation. We can look up a relevant `environment` through
    # `deployment` relation today.
    # (See more https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/22380)
    #
    # Since Gitlab 12.9, we started persisting the expanded environment name to
    # avoid repeated variables expansion in `action: stop` builds as well.
    def persisted_environment
      return unless has_environment?

      strong_memoize(:persisted_environment) do
        # This code path has caused N+1s in the past, since environments are only indirectly
        # associated to builds and pipelines; see https://gitlab.com/gitlab-org/gitlab/-/issues/326445
        # We therefore batch-load them to prevent dormant N+1s until we found a proper solution.
        BatchLoader.for(expanded_environment_name).batch(key: project_id) do |names, loader, args|
          Environment.where(name: names, project: args[:key]).find_each do |environment|
            loader.call(environment.name, environment)
          end
        end
      end
    end

    serialize :options # rubocop:disable Cop/ActiveRecordSerialize
    serialize :yaml_variables, Gitlab::Serializer::Ci::Variables # rubocop:disable Cop/ActiveRecordSerialize

    delegate :name, to: :project, prefix: true

    validates :coverage, numericality: true, allow_blank: true
    validates :ref, presence: true

    scope :not_interruptible, -> do
      joins(:metadata).where.not('ci_builds_metadata.id' => Ci::BuildMetadata.scoped_build.with_interruptible.select(:id))
    end

    scope :unstarted, -> { where(runner_id: nil) }
    scope :ignore_failures, -> { where(allow_failure: false) }
    scope :with_downloadable_artifacts, -> do
      where('EXISTS (?)',
        Ci::JobArtifact.select(1)
          .where('ci_builds.id = ci_job_artifacts.job_id')
          .where(file_type: Ci::JobArtifact::DOWNLOADABLE_TYPES)
      )
    end

    scope :in_pipelines, ->(pipelines) do
      where(pipeline: pipelines)
    end

    scope :with_existing_job_artifacts, ->(query) do
      where('EXISTS (?)', ::Ci::JobArtifact.select(1).where('ci_builds.id = ci_job_artifacts.job_id').merge(query))
    end

    scope :with_archived_trace, -> do
      with_existing_job_artifacts(Ci::JobArtifact.trace)
    end

    scope :without_archived_trace, -> do
      where('NOT EXISTS (?)', Ci::JobArtifact.select(1).where('ci_builds.id = ci_job_artifacts.job_id').trace)
    end

    scope :with_reports, ->(reports_scope) do
      with_existing_job_artifacts(reports_scope)
        .eager_load_job_artifacts
    end

    scope :eager_load_job_artifacts, -> { includes(:job_artifacts) }
    scope :eager_load_job_artifacts_archive, -> { includes(:job_artifacts_archive) }
    scope :eager_load_tags, -> { includes(:tags) }

    scope :eager_load_everything, -> do
      includes(
        [
          { pipeline: [:project, :user] },
          :job_artifacts_archive,
          :metadata,
          :trigger_request,
          :project,
          :user,
          :tags
        ]
      )
    end

    scope :with_exposed_artifacts, -> do
      joins(:metadata).merge(Ci::BuildMetadata.with_exposed_artifacts)
        .includes(:metadata, :job_artifacts_metadata)
    end

    scope :with_project_and_metadata, -> do
      if Feature.enabled?(:non_public_artifacts, type: :development)
        joins(:metadata).includes(:project, :metadata)
      end
    end

    scope :with_artifacts_not_expired, -> { with_downloadable_artifacts.where('artifacts_expire_at IS NULL OR artifacts_expire_at > ?', Time.current) }
    scope :with_expired_artifacts, -> { with_downloadable_artifacts.where('artifacts_expire_at < ?', Time.current) }
    scope :last_month, -> { where('created_at > ?', Date.today - 1.month) }
    scope :manual_actions, -> { where(when: :manual, status: COMPLETED_STATUSES + %i[manual]) }
    scope :scheduled_actions, -> { where(when: :delayed, status: COMPLETED_STATUSES + %i[scheduled]) }
    scope :ref_protected, -> { where(protected: true) }
    scope :with_live_trace, -> { where('EXISTS (?)', Ci::BuildTraceChunk.where('ci_builds.id = ci_build_trace_chunks.build_id').select(1)) }
    scope :with_stale_live_trace, -> { with_live_trace.finished_before(12.hours.ago) }
    scope :finished_before, -> (date) { finished.where('finished_at < ?', date) }

    scope :with_secure_reports_from_options, -> (job_type) { where('options like :job_type', job_type: "%:artifacts:%:reports:%:#{job_type}:%") }

    scope :with_secure_reports_from_config_options, -> (job_types) do
      joins(:metadata).where("ci_builds_metadata.config_options -> 'artifacts' -> 'reports' ?| array[:job_types]", job_types: job_types)
    end

    scope :queued_before, ->(time) { where(arel_table[:queued_at].lt(time)) }

    scope :preload_project_and_pipeline_project, -> do
      preload(Ci::Pipeline::PROJECT_ROUTE_AND_NAMESPACE_ROUTE,
              pipeline: Ci::Pipeline::PROJECT_ROUTE_AND_NAMESPACE_ROUTE)
    end

    scope :with_coverage, -> { where.not(coverage: nil) }
    scope :without_coverage, -> { where(coverage: nil) }
    scope :with_coverage_regex, -> { where.not(coverage_regex: nil) }

    scope :for_project, -> (project_id) { where(project_id: project_id) }

    acts_as_taggable

    add_authentication_token_field :token, encrypted: :required

    before_save :ensure_token
    before_destroy { unscoped_project }

    after_save :stick_build_if_status_changed

    after_create unless: :importing? do |build|
      run_after_commit { BuildHooksWorker.perform_async(build.id) }
    end

    class << self
      # This is needed for url_for to work,
      # as the controller is JobsController
      def model_name
        ActiveModel::Name.new(self, nil, 'job')
      end

      def first_pending
        pending.unstarted.order('created_at ASC').first
      end

      def retry(build, current_user)
        # rubocop: disable CodeReuse/ServiceClass
        Ci::RetryBuildService
          .new(build.project, current_user)
          .execute(build)
        # rubocop: enable CodeReuse/ServiceClass
      end

      def with_preloads
        preload(:job_artifacts_archive, :job_artifacts, :tags, project: [:namespace])
      end
    end

    state_machine :status do
      event :enqueue do
        transition [:created, :skipped, :manual, :scheduled] => :preparing, if: :any_unmet_prerequisites?
      end

      event :enqueue_scheduled do
        transition scheduled: :preparing, if: :any_unmet_prerequisites?
        transition scheduled: :pending
      end

      event :enqueue_preparing do
        transition preparing: :pending
      end

      event :actionize do
        transition created: :manual
      end

      event :schedule do
        transition created: :scheduled
      end

      event :unschedule do
        transition scheduled: :manual
      end

      before_transition on: :enqueue_scheduled do |build|
        build.scheduled_at.nil? || build.scheduled_at.past? # If false is returned, it stops the transition
      end

      before_transition scheduled: any do |build|
        build.scheduled_at = nil
      end

      before_transition created: :scheduled do |build|
        build.scheduled_at = build.options_scheduled_at
      end

      before_transition on: :enqueue_preparing do |build|
        !build.any_unmet_prerequisites? # If false is returned, it stops the transition
      end

      after_transition created: :scheduled do |build|
        build.run_after_commit do
          Ci::BuildScheduleWorker.perform_at(build.scheduled_at, build.id)
        end
      end

      after_transition any => [:preparing] do |build|
        build.run_after_commit do
          Ci::BuildPrepareWorker.perform_async(id)
        end
      end

      # rubocop:disable CodeReuse/ServiceClass
      after_transition any => [:pending] do |build, transition|
        Ci::UpdateBuildQueueService.new.push(build, transition)

        build.run_after_commit do
          BuildQueueWorker.perform_async(id)
        end
      end

      after_transition pending: any do |build, transition|
        Ci::UpdateBuildQueueService.new.pop(build, transition)
      end

      after_transition any => [:running] do |build, transition|
        Ci::UpdateBuildQueueService.new.track(build, transition)
      end

      after_transition running: any do |build, transition|
        Ci::UpdateBuildQueueService.new.untrack(build, transition)

        Ci::BuildRunnerSession.where(build: build).delete_all
      end

      # rubocop:enable CodeReuse/ServiceClass
      #
      after_transition pending: :running do |build|
        build.ensure_metadata.update_timeout_state
      end

      after_transition pending: :running do |build|
        build.deployment&.run

        build.run_after_commit do
          build.pipeline.persistent_ref.create

          BuildHooksWorker.perform_async(id)
        end
      end

      after_transition any => [:success, :failed, :canceled] do |build|
        build.run_after_commit do
          build.run_status_commit_hooks!

          BuildFinishedWorker.perform_async(id)
        end
      end

      after_transition any => [:success] do |build|
        build.deployment&.succeed

        build.run_after_commit do
          BuildSuccessWorker.perform_async(id)
          PagesWorker.perform_async(:deploy, id) if build.pages_generator?
        end
      end

      after_transition any => [:failed] do |build|
        next unless build.project
        next unless build.deployment

        begin
          build.deployment.drop!
        rescue StandardError => e
          Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e, build_id: build.id)
        end

        true
      end

      after_transition any => [:failed] do |build|
        next unless build.project

        if build.auto_retry_allowed?
          begin
            Ci::Build.retry(build, build.user)
          rescue Gitlab::Access::AccessDeniedError => ex
            Gitlab::AppLogger.error "Unable to auto-retry job #{build.id}: #{ex}"
          end
        end
      end

      after_transition any => [:skipped, :canceled] do |build, transition|
        if transition.to_name == :skipped
          build.deployment&.skip
        else
          build.deployment&.cancel
        end
      end
    end

    def self.build_matchers(project)
      unique_params = [
        :protected,
        Arel.sql("(#{arel_tag_names_array.to_sql})")
      ]

      group(*unique_params).pluck('array_agg(id)', *unique_params).map do |values|
        Gitlab::Ci::Matching::BuildMatcher.new({
          build_ids: values[0],
          protected: values[1],
          tag_list: values[2],
          project: project
        })
      end
    end

    def build_matcher
      strong_memoize(:build_matcher) do
        Gitlab::Ci::Matching::BuildMatcher.new({
          protected: protected?,
          tag_list: tag_list,
          build_ids: [id],
          project: project
        })
      end
    end

    def auto_retry_allowed?
      auto_retry.allowed?
    end

    def detailed_status(current_user)
      Gitlab::Ci::Status::Build::Factory
        .new(self.present, current_user)
        .fabricate!
    end

    def other_manual_actions
      pipeline.manual_actions.reject { |action| action.name == self.name }
    end

    def other_scheduled_actions
      pipeline.scheduled_actions.reject { |action| action.name == self.name }
    end

    def pages_generator?
      Gitlab.config.pages.enabled &&
        self.name == 'pages'
    end

    def runnable?
      true
    end

    def archived?
      return true if degenerated?

      archive_builds_older_than = Gitlab::CurrentSettings.current_application_settings.archive_builds_older_than
      archive_builds_older_than.present? && created_at < archive_builds_older_than
    end

    def playable?
      action? && !archived? && (manual? || scheduled? || retryable?)
    end

    def schedulable?
      self.when == 'delayed' && options[:start_in].present?
    end

    def options_scheduled_at
      ChronicDuration.parse(options[:start_in])&.seconds&.from_now
    end

    def action?
      %w[manual delayed].include?(self.when)
    end

    # rubocop: disable CodeReuse/ServiceClass
    def play(current_user, job_variables_attributes = nil)
      Ci::PlayBuildService
        .new(project, current_user)
        .execute(self, job_variables_attributes)
    end
    # rubocop: enable CodeReuse/ServiceClass

    def cancelable?
      active? || created?
    end

    def retryable?
      if Feature.enabled?(:prevent_retry_of_retried_jobs, project, default_enabled: :yaml)
        return false if retried? || archived?

        success? || failed? || canceled?
      else
        !archived? && (success? || failed? || canceled?)
      end
    end

    def retries_count
      pipeline.builds.retried.where(name: self.name).count
    end

    override :all_met_to_become_pending?
    def all_met_to_become_pending?
      super && !any_unmet_prerequisites?
    end

    def any_unmet_prerequisites?
      prerequisites.present?
    end

    def prerequisites
      Gitlab::Ci::Build::Prerequisite::Factory.new(self).unmet
    end

    def expanded_environment_name
      return unless has_environment?

      strong_memoize(:expanded_environment_name) do
        # We're using a persisted expanded environment name in order to avoid
        # variable expansion per request.
        if metadata&.expanded_environment_name.present?
          metadata.expanded_environment_name
        else
          ExpandVariables.expand(environment, -> { simple_variables })
        end
      end
    end

    def expanded_kubernetes_namespace
      return unless has_environment?

      namespace = options.dig(:environment, :kubernetes, :namespace)

      if namespace.present?
        strong_memoize(:expanded_kubernetes_namespace) do
          ExpandVariables.expand(namespace, -> { simple_variables })
        end
      end
    end

    def has_environment?
      environment.present?
    end

    def starts_environment?
      has_environment? && self.environment_action == 'start'
    end

    def stops_environment?
      has_environment? && self.environment_action == 'stop'
    end

    def environment_action
      self.options.fetch(:environment, {}).fetch(:action, 'start') if self.options
    end

    def environment_deployment_tier
      self.options.dig(:environment, :deployment_tier) if self.options
    end

    def outdated_deployment?
      success? && !deployment.try(:last?)
    end

    def triggered_by?(current_user)
      user == current_user
    end

    def on_stop
      options&.dig(:environment, :on_stop)
    end

    ##
    # All variables, including persisted environment variables.
    #
    def variables
      strong_memoize(:variables) do
        Gitlab::Ci::Variables::Collection.new
          .concat(persisted_variables)
          .concat(dependency_proxy_variables)
          .concat(job_jwt_variables)
          .concat(scoped_variables)
          .concat(job_variables)
          .concat(persisted_environment_variables)
      end
    end

    def persisted_variables
      Gitlab::Ci::Variables::Collection.new.tap do |variables|
        break variables unless persisted?

        variables
          .concat(pipeline.persisted_variables)
          .append(key: 'CI_JOB_ID', value: id.to_s)
          .append(key: 'CI_JOB_URL', value: Gitlab::Routing.url_helpers.project_job_url(project, self))
          .append(key: 'CI_JOB_TOKEN', value: token.to_s, public: false, masked: true)
          .append(key: 'CI_JOB_STARTED_AT', value: started_at&.iso8601)
          .append(key: 'CI_BUILD_ID', value: id.to_s)
          .append(key: 'CI_BUILD_TOKEN', value: token.to_s, public: false, masked: true)
          .append(key: 'CI_REGISTRY_USER', value: ::Gitlab::Auth::CI_JOB_USER)
          .append(key: 'CI_REGISTRY_PASSWORD', value: token.to_s, public: false, masked: true)
          .append(key: 'CI_REPOSITORY_URL', value: repo_url.to_s, public: false)
          .concat(deploy_token_variables)
      end
    end

    def persisted_environment_variables
      Gitlab::Ci::Variables::Collection.new.tap do |variables|
        break variables unless persisted? && persisted_environment.present?

        variables.concat(persisted_environment.predefined_variables)

        variables.append(key: 'CI_ENVIRONMENT_ACTION', value: environment_action)

        # Here we're passing unexpanded environment_url for runner to expand,
        # and we need to make sure that CI_ENVIRONMENT_NAME and
        # CI_ENVIRONMENT_SLUG so on are available for the URL be expanded.
        variables.append(key: 'CI_ENVIRONMENT_URL', value: environment_url) if environment_url
      end
    end

    def deploy_token_variables
      Gitlab::Ci::Variables::Collection.new.tap do |variables|
        break variables unless gitlab_deploy_token

        variables.append(key: 'CI_DEPLOY_USER', value: gitlab_deploy_token.username)
        variables.append(key: 'CI_DEPLOY_PASSWORD', value: gitlab_deploy_token.token, public: false, masked: true)
      end
    end

    def dependency_proxy_variables
      Gitlab::Ci::Variables::Collection.new.tap do |variables|
        break variables unless Gitlab.config.dependency_proxy.enabled

        variables.append(key: 'CI_DEPENDENCY_PROXY_USER', value: ::Gitlab::Auth::CI_JOB_USER)
        variables.append(key: 'CI_DEPENDENCY_PROXY_PASSWORD', value: token.to_s, public: false, masked: true)
      end
    end

    def features
      {
        trace_sections: true,
        failure_reasons: self.class.failure_reasons.keys
      }
    end

    def merge_request
      strong_memoize(:merge_request) do
        pipeline.all_merge_requests.order(iid: :asc).first
      end
    end

    def repo_url
      return unless token

      auth = "#{::Gitlab::Auth::CI_JOB_USER}:#{token}@"
      project.http_url_to_repo.sub(%r{^https?://}) do |prefix|
        prefix + auth
      end
    end

    def allow_git_fetch
      project.build_allow_git_fetch
    end

    def update_coverage
      coverage = trace.extract_coverage(coverage_regex)
      update(coverage: coverage) if coverage.present?
    end

    # rubocop: disable CodeReuse/ServiceClass
    def parse_trace_sections!
      ExtractSectionsFromBuildTraceService.new(project, user).execute(self)
    end
    # rubocop: enable CodeReuse/ServiceClass

    def trace
      Gitlab::Ci::Trace.new(self)
    end

    def has_trace?
      trace.exist?
    end

    def has_live_trace?
      trace.live_trace_exist?
    end

    def has_archived_trace?
      trace.archived_trace_exist?
    end

    def artifacts_file
      job_artifacts_archive&.file
    end

    def artifacts_size
      job_artifacts_archive&.size
    end

    def artifacts_metadata
      job_artifacts_metadata&.file
    end

    def artifacts?
      !artifacts_expired? && artifacts_file&.exists?
    end

    def locked_artifacts?
      pipeline.artifacts_locked? && artifacts_file&.exists?
    end

    # This method is similar to #artifacts? but it includes the artifacts
    # locking mechanics. A new method was created to prevent breaking existing
    # behavior and avoid introducing N+1s.
    def available_artifacts?
      (!artifacts_expired? || pipeline.artifacts_locked?) && job_artifacts_archive&.exists?
    end

    def artifacts_metadata?
      artifacts? && artifacts_metadata&.exists?
    end

    def has_job_artifacts?
      job_artifacts.any?
    end

    def has_test_reports?
      job_artifacts.test_reports.exists?
    end

    def has_old_trace?
      old_trace.present?
    end

    def trace=(data)
      raise NotImplementedError
    end

    def old_trace
      read_attribute(:trace)
    end

    def erase_old_trace!
      return unless has_old_trace?

      update_column(:trace, nil)
    end

    def artifacts_expose_as
      options.dig(:artifacts, :expose_as)
    end

    def artifacts_paths
      options.dig(:artifacts, :paths)
    end

    def needs_touch?
      Time.current - updated_at > 15.minutes.to_i
    end

    def valid_token?(token)
      self.token && ActiveSupport::SecurityUtils.secure_compare(token, self.token)
    end

    def tag_list
      if tags.loaded?
        tags.map(&:name)
      else
        super
      end
    end

    def has_tags?
      tag_list.any?
    end

    def any_runners_online?
      cache_for_online_runners do
        project.any_online_runners? { |runner| runner.match_build_if_online?(self) }
      end
    end

    def any_runners_available?
      cache_for_available_runners do
        project.active_runners.exists?
      end
    end

    def stuck?
      pending? && !any_runners_online?
    end

    def execute_hooks
      return unless project

      project.execute_hooks(build_data.dup, :job_hooks) if project.has_active_hooks?(:job_hooks)
      project.execute_integrations(build_data.dup, :job_hooks) if project.has_active_integrations?(:job_hooks)
    end

    def browsable_artifacts?
      artifacts_metadata?
    end

    def artifacts_public?
      return true unless Feature.enabled?(:non_public_artifacts, type: :development)

      artifacts_public = options.dig(:artifacts, :public)

      return true if artifacts_public.nil? # Default artifacts:public to true

      options.dig(:artifacts, :public)
    end

    def artifacts_metadata_entry(path, **options)
      artifacts_metadata.open do |metadata_stream|
        metadata = Gitlab::Ci::Build::Artifacts::Metadata.new(
          metadata_stream,
          path,
          **options)

        metadata.to_entry
      end
    end

    # and use that for `ExpireBuildInstanceArtifactsWorker`?
    def erase_erasable_artifacts!
      job_artifacts.erasable.destroy_all # rubocop: disable Cop/DestroyAll
    end

    def erase(opts = {})
      return false unless erasable?

      job_artifacts.destroy_all # rubocop: disable Cop/DestroyAll
      erase_trace!
      update_erased!(opts[:erased_by])
    end

    def erasable?
      complete? && (artifacts? || has_job_artifacts? || has_trace?)
    end

    def erased?
      !self.erased_at.nil?
    end

    def artifacts_expired?
      artifacts_expire_at && artifacts_expire_at < Time.current
    end

    def artifacts_expire_in
      artifacts_expire_at - Time.current if artifacts_expire_at
    end

    def artifacts_expire_in=(value)
      self.artifacts_expire_at =
        if value
          ChronicDuration.parse(value)&.seconds&.from_now
        end
    end

    def has_expired_locked_archive_artifacts?
      locked_artifacts? &&
        artifacts_expire_at.present? && artifacts_expire_at < Time.current
    end

    def has_expiring_archive_artifacts?
      has_expiring_artifacts? && job_artifacts_archive.present?
    end

    def self.keep_artifacts!
      update_all(artifacts_expire_at: nil)
      Ci::JobArtifact.where(job: self.select(:id)).update_all(expire_at: nil)
    end

    def keep_artifacts!
      self.update(artifacts_expire_at: nil)
      self.job_artifacts.update_all(expire_at: nil)
    end

    def artifacts_file_for_type(type)
      file_types = Ci::JobArtifact.associated_file_types_for(type)
      file_types_ids = file_types&.map { |file_type| Ci::JobArtifact.file_types[file_type] }
      job_artifacts.find_by(file_type: file_types_ids)&.file
    end

    def coverage_regex
      super || project.try(:build_coverage_regex)
    end

    def steps
      [Gitlab::Ci::Build::Step.from_commands(self),
       Gitlab::Ci::Build::Step.from_release(self),
       Gitlab::Ci::Build::Step.from_after_script(self)].compact
    end

    def image
      Gitlab::Ci::Build::Image.from_image(self)
    end

    def services
      Gitlab::Ci::Build::Image.from_services(self)
    end

    def cache
      cache = Array.wrap(options[:cache])

      if project.jobs_cache_index
        cache = cache.map do |single_cache|
          single_cache.merge(key: "#{single_cache[:key]}-#{project.jobs_cache_index}")
        end
      end

      cache
    end

    def credentials
      Gitlab::Ci::Build::Credentials::Factory.new(self).create!
    end

    def has_valid_build_dependencies?
      dependencies.valid?
    end

    def invalid_dependencies
      dependencies.invalid_local
    end

    def valid_dependency?
      return false if artifacts_expired?
      return false if erased?

      true
    end

    def runner_required_feature_names
      strong_memoize(:runner_required_feature_names) do
        RUNNER_FEATURES.select do |feature, method|
          method.call(self)
        end.keys
      end
    end

    def supported_runner?(features)
      runner_required_feature_names.all? do |feature_name|
        features&.dig(feature_name)
      end
    end

    def publishes_artifacts_reports?
      options&.dig(:artifacts, :reports)&.any?
    end

    def supports_artifacts_exclude?
      options&.dig(:artifacts, :exclude)&.any?
    end

    def multi_build_steps?
      options.dig(:release)&.any?
    end

    def hide_secrets(data, metrics = ::Gitlab::Ci::Trace::Metrics.new)
      return unless trace

      data.dup.tap do |trace|
        Gitlab::Ci::MaskSecret.mask!(trace, project.runners_token) if project
        Gitlab::Ci::MaskSecret.mask!(trace, token) if token

        if trace != data
          metrics.increment_trace_operation(operation: :mutated)
        end
      end
    end

    def serializable_hash(options = {})
      super(options).merge(when: read_attribute(:when))
    end

    def has_terminal?
      running? && runner_session_url.present?
    end

    def collect_test_reports!(test_reports)
      test_reports.get_suite(group_name).tap do |test_suite|
        each_report(Ci::JobArtifact::TEST_REPORT_FILE_TYPES) do |file_type, blob|
          Gitlab::Ci::Parsers.fabricate!(file_type).parse!(
            blob,
            test_suite,
            job: self
          )
        end
      end
    end

    def collect_accessibility_reports!(accessibility_report)
      each_report(Ci::JobArtifact::ACCESSIBILITY_REPORT_FILE_TYPES) do |file_type, blob|
        Gitlab::Ci::Parsers.fabricate!(file_type).parse!(blob, accessibility_report)
      end

      accessibility_report
    end

    def collect_coverage_reports!(coverage_report)
      each_report(Ci::JobArtifact::COVERAGE_REPORT_FILE_TYPES) do |file_type, blob|
        Gitlab::Ci::Parsers.fabricate!(file_type).parse!(
          blob,
          coverage_report,
          project_path: project.full_path,
          worktree_paths: pipeline.all_worktree_paths
        )
      end

      coverage_report
    end

    def collect_codequality_reports!(codequality_report)
      each_report(Ci::JobArtifact::CODEQUALITY_REPORT_FILE_TYPES) do |file_type, blob|
        Gitlab::Ci::Parsers.fabricate!(file_type).parse!(blob, codequality_report)
      end

      codequality_report
    end

    def collect_terraform_reports!(terraform_reports)
      each_report(::Ci::JobArtifact::TERRAFORM_REPORT_FILE_TYPES) do |file_type, blob, report_artifact|
        ::Gitlab::Ci::Parsers.fabricate!(file_type).parse!(blob, terraform_reports, artifact: report_artifact)
      end

      terraform_reports
    end

    def report_artifacts
      job_artifacts.with_reports
    end

    # Virtual deployment status depending on the environment status.
    def deployment_status
      return unless starts_environment?

      if success?
        return successful_deployment_status
      elsif failed?
        return :failed
      end

      :creating
    end

    # Consider this object to have a structural integrity problems
    def doom!
      update_columns(
        status: :failed,
        failure_reason: :data_integrity_failure)
    end

    def degradation_threshold
      var = yaml_variables.find { |v| v[:key] == DEGRADATION_THRESHOLD_VARIABLE_NAME }
      var[:value]&.to_i if var
    end

    def remove_pending_state!
      pending_state.try(:delete)
    end

    def run_on_status_commit(&block)
      status_commit_hooks.push(block)
    end

    def max_test_cases_per_report
      # NOTE: This is temporary and will be replaced later by a value
      # that would come from an actual application limit.
      ::Gitlab.com? ? 500_000 : 0
    end

    def debug_mode?
      # TODO: Have `debug_mode?` check against data on sent back from runner
      # to capture all the ways that variables can be set.
      # See (https://gitlab.com/gitlab-org/gitlab/-/issues/290955)
      variables['CI_DEBUG_TRACE']&.value&.casecmp('true') == 0
    end

    def drop_with_exit_code!(failure_reason, exit_code)
      transaction do
        conditionally_allow_failure!(exit_code)
        drop!(failure_reason)
      end
    end

    def exit_codes_defined?
      options.dig(:allow_failure_criteria, :exit_codes).present?
    end

    def create_queuing_entry!
      ::Ci::PendingBuild.upsert_from_build!(self)
    end

    ##
    # We can have only one queuing entry or running build tracking entry,
    # because there is a unique index on `build_id` in each table, but we need
    # a relation to remove these entries more efficiently in a single statement
    # without actually loading data.
    #
    def all_queuing_entries
      ::Ci::PendingBuild.where(build_id: self.id)
    end

    def all_runtime_metadata
      ::Ci::RunningBuild.where(build_id: self.id)
    end

    def shared_runner_build?
      runner&.instance_type?
    end

    protected

    def run_status_commit_hooks!
      status_commit_hooks.reverse_each do |hook|
        instance_eval(&hook)
      end
    end

    private

    def stick_build_if_status_changed
      return unless saved_change_to_status?
      return unless running?

      ::Gitlab::Database::LoadBalancing::Sticking.stick(:build, id)
    end

    def status_commit_hooks
      @status_commit_hooks ||= []
    end

    def auto_retry
      strong_memoize(:auto_retry) do
        Gitlab::Ci::Build::AutoRetry.new(self)
      end
    end

    def build_data
      strong_memoize(:build_data) { Gitlab::DataBuilder::Build.build(self) }
    end

    def successful_deployment_status
      if deployment&.last?
        :last
      else
        :out_of_date
      end
    end

    def each_report(report_types)
      job_artifacts_for_types(report_types).each do |report_artifact|
        report_artifact.each_blob do |blob|
          yield report_artifact.file_type, blob, report_artifact
        end
      end
    end

    def job_artifacts_for_types(report_types)
      # Use select to leverage cached associations and avoid N+1 queries
      job_artifacts.select { |artifact| artifact.file_type.in?(report_types) }
    end

    def erase_trace!
      trace.erase!
    end

    def update_erased!(user = nil)
      self.update(erased_by: user, erased_at: Time.current, artifacts_expire_at: nil)
    end

    def unscoped_project
      @unscoped_project ||= Project.unscoped.find_by(id: project_id)
    end

    def environment_url
      options&.dig(:environment, :url) || persisted_environment&.external_url
    end

    def environment_status
      strong_memoize(:environment_status) do
        if has_environment? && merge_request
          EnvironmentStatus.new(project, persisted_environment, merge_request, pipeline.sha)
        end
      end
    end

    def has_expiring_artifacts?
      artifacts_expire_at.present? && artifacts_expire_at > Time.current
    end

    def job_jwt_variables
      Gitlab::Ci::Variables::Collection.new.tap do |variables|
        break variables unless Feature.enabled?(:ci_job_jwt, project, default_enabled: true)

        jwt = Gitlab::Ci::Jwt.for_build(self)
        variables.append(key: 'CI_JOB_JWT', value: jwt, public: false, masked: true)
      rescue OpenSSL::PKey::RSAError, Gitlab::Ci::Jwt::NoSigningKeyError => e
        Gitlab::ErrorTracking.track_exception(e)
      end
    end

    def conditionally_allow_failure!(exit_code)
      return unless exit_code

      if allowed_to_fail_with_code?(exit_code)
        update_columns(allow_failure: true)
      end
    end

    def allowed_to_fail_with_code?(exit_code)
      options
        .dig(:allow_failure_criteria, :exit_codes)
        .to_a
        .include?(exit_code)
    end

    def cache_for_online_runners(&block)
      Rails.cache.fetch(
        ['has-online-runners', id],
        expires_in: RUNNERS_STATUS_CACHE_EXPIRATION
      ) { yield }
    end

    def cache_for_available_runners(&block)
      Rails.cache.fetch(
        ['has-available-runners', project.id],
        expires_in: RUNNERS_STATUS_CACHE_EXPIRATION
      ) { yield }
    end
  end
end

Ci::Build.prepend_mod_with('Ci::Build')
