# frozen_string_literal: true

module Ci
  class Build < CommitStatus
    include Ci::Processable
    include Ci::Metadatable
    include Ci::Contextable
    include Ci::PipelineDelegator
    include TokenAuthenticatable
    include AfterCommitQueue
    include ObjectStorage::BackgroundMove
    include Presentable
    include Importable
    include Gitlab::Utils::StrongMemoize
    include HasRef
    include IgnorableColumns

    BuildArchivedError = Class.new(StandardError)

    ignore_columns :artifacts_file, :artifacts_file_store, :artifacts_metadata, :artifacts_metadata_store, :artifacts_size, :commands, remove_after: '2019-12-15', remove_with: '12.7'

    belongs_to :project, inverse_of: :builds
    belongs_to :runner
    belongs_to :trigger_request
    belongs_to :erased_by, class_name: 'User'
    belongs_to :resource_group, class_name: 'Ci::ResourceGroup', inverse_of: :builds

    RUNNER_FEATURES = {
      upload_multiple_artifacts: -> (build) { build.publishes_artifacts_reports? },
      refspecs: -> (build) { build.merge_request_ref? }
    }.freeze

    DEFAULT_RETRIES = {
      scheduler_failure: 2
    }.freeze

    has_one :deployment, as: :deployable, class_name: 'Deployment'
    has_one :resource, class_name: 'Ci::Resource', inverse_of: :build
    has_many :trace_sections, class_name: 'Ci::BuildTraceSection'
    has_many :trace_chunks, class_name: 'Ci::BuildTraceChunk', foreign_key: :build_id

    has_many :job_artifacts, class_name: 'Ci::JobArtifact', foreign_key: :job_id, dependent: :destroy, inverse_of: :job # rubocop:disable Cop/ActiveRecordDependent
    has_many :job_variables, class_name: 'Ci::JobVariable', foreign_key: :job_id
    has_many :sourced_pipelines, class_name: 'Ci::Sources::Pipeline', foreign_key: :source_job_id

    Ci::JobArtifact.file_types.each do |key, value|
      has_one :"job_artifacts_#{key}", -> { where(file_type: value) }, class_name: 'Ci::JobArtifact', inverse_of: :job, foreign_key: :job_id
    end

    has_one :runner_session, class_name: 'Ci::BuildRunnerSession', validate: true, inverse_of: :build

    accepts_nested_attributes_for :runner_session, update_only: true
    accepts_nested_attributes_for :job_variables

    delegate :url, to: :runner_session, prefix: true, allow_nil: true
    delegate :terminal_specification, to: :runner_session, allow_nil: true
    delegate :gitlab_deploy_token, to: :project
    delegate :trigger_short_token, to: :trigger_request, allow_nil: true

    ##
    # Since Gitlab 11.5, deployments records started being created right after
    # `ci_builds` creation. We can look up a relevant `environment` through
    # `deployment` relation today. This is much more efficient than expanding
    # environment name with variables.
    # (See more https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/22380)
    #
    # However, we have to still expand environment name if it's a stop action,
    # because `deployment` persists information for start action only.
    #
    # We will follow up this by persisting expanded name in build metadata or
    # persisting stop action in database.
    def persisted_environment
      return unless has_environment?

      strong_memoize(:persisted_environment) do
        deployment&.environment ||
          Environment.find_by(name: expanded_environment_name, project: project)
      end
    end

    serialize :options # rubocop:disable Cop/ActiveRecordSerialize
    serialize :yaml_variables, Gitlab::Serializer::Ci::Variables # rubocop:disable Cop/ActiveRecordSerialize

    delegate :name, to: :project, prefix: true

    validates :coverage, numericality: true, allow_blank: true
    validates :ref, presence: true

    scope :not_interruptible, -> do
      joins(:metadata).where('ci_builds_metadata.id NOT IN (?)',
        Ci::BuildMetadata.scoped_build.with_interruptible.select(:id))
    end

    scope :unstarted, ->() { where(runner_id: nil) }
    scope :ignore_failures, ->() { where(allow_failure: false) }
    scope :with_artifacts_archive, ->() do
      where('EXISTS (?)', Ci::JobArtifact.select(1).where('ci_builds.id = ci_job_artifacts.job_id').archive)
    end

    scope :with_existing_job_artifacts, ->(query) do
      where('EXISTS (?)', ::Ci::JobArtifact.select(1).where('ci_builds.id = ci_job_artifacts.job_id').merge(query))
    end

    scope :with_archived_trace, ->() do
      with_existing_job_artifacts(Ci::JobArtifact.trace)
    end

    scope :without_archived_trace, ->() do
      where('NOT EXISTS (?)', Ci::JobArtifact.select(1).where('ci_builds.id = ci_job_artifacts.job_id').trace)
    end

    scope :with_reports, ->(reports_scope) do
      with_existing_job_artifacts(reports_scope)
        .eager_load_job_artifacts
    end

    scope :eager_load_job_artifacts, -> { includes(:job_artifacts) }

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

    scope :with_artifacts_not_expired, ->() { with_artifacts_archive.where('artifacts_expire_at IS NULL OR artifacts_expire_at > ?', Time.now) }
    scope :with_expired_artifacts, ->() { with_artifacts_archive.where('artifacts_expire_at < ?', Time.now) }
    scope :last_month, ->() { where('created_at > ?', Date.today - 1.month) }
    scope :manual_actions, ->() { where(when: :manual, status: COMPLETED_STATUSES + %i[manual]) }
    scope :scheduled_actions, ->() { where(when: :delayed, status: COMPLETED_STATUSES + %i[scheduled]) }
    scope :ref_protected, -> { where(protected: true) }
    scope :with_live_trace, -> { where('EXISTS (?)', Ci::BuildTraceChunk.where('ci_builds.id = ci_build_trace_chunks.build_id').select(1)) }
    scope :with_stale_live_trace, -> { with_live_trace.finished_before(12.hours.ago) }
    scope :finished_before, -> (date) { finished.where('finished_at < ?', date) }

    scope :with_secure_reports_from_options, -> (job_type) { where('options like :job_type', job_type: "%:artifacts:%:reports:%:#{job_type}:%") }

    scope :with_secure_reports_from_config_options, -> (job_types) do
      joins(:metadata).where("ci_builds_metadata.config_options -> 'artifacts' -> 'reports' ?| array[:job_types]", job_types: job_types)
    end

    scope :matches_tag_ids, -> (tag_ids) do
      matcher = ::ActsAsTaggableOn::Tagging
        .where(taggable_type: CommitStatus.name)
        .where(context: 'tags')
        .where('taggable_id = ci_builds.id')
        .where.not(tag_id: tag_ids).select('1')

      where("NOT EXISTS (?)", matcher)
    end

    scope :with_any_tags, -> do
      matcher = ::ActsAsTaggableOn::Tagging
        .where(taggable_type: CommitStatus.name)
        .where(context: 'tags')
        .where('taggable_id = ci_builds.id').select('1')

      where("EXISTS (?)", matcher)
    end

    scope :queued_before, ->(time) { where(arel_table[:queued_at].lt(time)) }
    scope :order_id_desc, -> { order('ci_builds.id DESC') }

    acts_as_taggable

    add_authentication_token_field :token, encrypted: :optional

    before_save :ensure_token
    before_destroy { unscoped_project }

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
    end

    state_machine :status do
      event :enqueue do
        transition [:created, :skipped, :manual, :scheduled] => :preparing, if: :any_unmet_prerequisites?
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

      event :enqueue_scheduled do
        transition scheduled: :preparing, if: ->(build) do
          build.scheduled_at&.past? && build.any_unmet_prerequisites?
        end

        transition scheduled: :pending, if: ->(build) do
          build.scheduled_at&.past? && !build.any_unmet_prerequisites?
        end
      end

      before_transition scheduled: any do |build|
        build.scheduled_at = nil
      end

      before_transition created: :scheduled do |build|
        build.scheduled_at = build.options_scheduled_at
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

      after_transition any => [:pending] do |build|
        build.run_after_commit do
          BuildQueueWorker.perform_async(id)
        end
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

      before_transition any => [:failed] do |build|
        next unless build.project
        next unless build.deployment

        begin
          build.deployment.drop!
        rescue => e
          Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e, build_id: build.id)
        end

        true
      end

      after_transition any => [:failed] do |build|
        next unless build.project

        if build.retry_failure?
          begin
            Ci::Build.retry(build, build.user)
          rescue Gitlab::Access::AccessDeniedError => ex
            Rails.logger.error "Unable to auto-retry job #{build.id}: #{ex}" # rubocop:disable Gitlab/RailsLogger
          end
        end
      end

      after_transition pending: :running do |build|
        build.ensure_metadata.update_timeout_state
      end

      after_transition running: any do |build|
        Ci::BuildRunnerSession.where(build: build).delete_all
      end

      after_transition any => [:skipped, :canceled] do |build|
        build.deployment&.cancel
      end
    end

    def detailed_status(current_user)
      Gitlab::Ci::Status::Build::Factory
        .new(self, current_user)
        .fabricate!
    end

    def other_manual_actions
      pipeline.manual_actions.where.not(name: name)
    end

    def other_scheduled_actions
      pipeline.scheduled_actions.where.not(name: name)
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
      !archived? && (success? || failed? || canceled?)
    end

    def retries_count
      pipeline.builds.retried.where(name: self.name).count
    end

    def retry_failure?
      max_allowed_retries = nil
      max_allowed_retries ||= options_retry_max if retry_on_reason_or_always?
      max_allowed_retries ||= DEFAULT_RETRIES.fetch(failure_reason.to_sym, 0)

      max_allowed_retries > 0 && retries_count < max_allowed_retries
    end

    def options_retry_max
      options_retry[:max]
    end

    def options_retry_when
      options_retry.fetch(:when, ['always'])
    end

    def retry_on_reason_or_always?
      options_retry_when.include?(failure_reason.to_s) ||
        options_retry_when.include?('always')
    end

    def latest?
      !retried?
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
        ExpandVariables.expand(environment, -> { simple_variables })
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

    def outdated_deployment?
      success? && !deployment.try(:last?)
    end

    def depends_on_builds
      # Get builds of the same type
      latest_builds = self.pipeline.builds.latest

      # Return builds from previous stages
      latest_builds.where('stage_idx < ?', stage_idx)
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
          .concat(scoped_variables)
          .concat(job_variables)
          .concat(persisted_environment_variables)
          .to_runner_variables
      end
    end

    CI_REGISTRY_USER = 'gitlab-ci-token'

    def persisted_variables
      Gitlab::Ci::Variables::Collection.new.tap do |variables|
        break variables unless persisted?

        variables
          .concat(pipeline.persisted_variables)
          .append(key: 'CI_JOB_ID', value: id.to_s)
          .append(key: 'CI_JOB_URL', value: Gitlab::Routing.url_helpers.project_job_url(project, self))
          .append(key: 'CI_JOB_TOKEN', value: token.to_s, public: false, masked: true)
          .append(key: 'CI_BUILD_ID', value: id.to_s)
          .append(key: 'CI_BUILD_TOKEN', value: token.to_s, public: false, masked: true)
          .append(key: 'CI_REGISTRY_USER', value: CI_REGISTRY_USER)
          .append(key: 'CI_REGISTRY_PASSWORD', value: token.to_s, public: false, masked: true)
          .append(key: 'CI_REPOSITORY_URL', value: repo_url.to_s, public: false)
          .concat(deploy_token_variables)
      end
    end

    def persisted_environment_variables
      Gitlab::Ci::Variables::Collection.new.tap do |variables|
        break variables unless persisted? && persisted_environment.present?

        variables.concat(persisted_environment.predefined_variables)

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

    def features
      { trace_sections: true }
    end

    def merge_request
      return @merge_request if defined?(@merge_request)

      @merge_request ||=
        begin
          merge_requests = MergeRequest.includes(:latest_merge_request_diff)
            .where(source_branch: ref,
                   source_project: pipeline.project)
            .reorder(iid: :desc)

          merge_requests.find do |merge_request|
            merge_request.commit_shas.include?(pipeline.sha)
          end
        end
    end

    def repo_url
      return unless token

      auth = "gitlab-ci-token:#{token}@"
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

    def artifacts_metadata?
      artifacts? && artifacts_metadata&.exists?
    end

    def has_job_artifacts?
      job_artifacts.any?
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
      Time.now - updated_at > 15.minutes.to_i
    end

    def valid_token?(token)
      self.token && ActiveSupport::SecurityUtils.secure_compare(token, self.token)
    end

    def has_tags?
      tag_list.any?
    end

    def any_runners_online?
      project.any_runners? { |runner| runner.active? && runner.online? && runner.can_pick?(self) }
    end

    def stuck?
      pending? && !any_runners_online?
    end

    def execute_hooks
      return unless project

      project.execute_hooks(build_data.dup, :job_hooks) if project.has_active_hooks?(:job_hooks)
      project.execute_services(build_data.dup, :job_hooks) if project.has_active_services?(:job_hooks)
    end

    def browsable_artifacts?
      artifacts_metadata?
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
      job_artifacts.erasable.destroy_all # rubocop: disable DestroyAll
    end

    def erase(opts = {})
      return false unless erasable?

      job_artifacts.destroy_all # rubocop: disable DestroyAll
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
      artifacts_expire_at && artifacts_expire_at < Time.now
    end

    def artifacts_expire_in
      artifacts_expire_at - Time.now if artifacts_expire_at
    end

    def artifacts_expire_in=(value)
      self.artifacts_expire_at =
        if value
          ChronicDuration.parse(value)&.seconds&.from_now
        end
    end

    def has_expiring_artifacts?
      artifacts_expire_at.present? && artifacts_expire_at > Time.now
    end

    def keep_artifacts!
      self.update(artifacts_expire_at: nil)
      self.job_artifacts.update_all(expire_at: nil)
    end

    def artifacts_file_for_type(type)
      job_artifacts.find_by(file_type: Ci::JobArtifact.file_types[type])&.file
    end

    def coverage_regex
      super || project.try(:build_coverage_regex)
    end

    def steps
      [Gitlab::Ci::Build::Step.from_commands(self),
       Gitlab::Ci::Build::Step.from_after_script(self)].compact
    end

    def image
      Gitlab::Ci::Build::Image.from_image(self)
    end

    def services
      Gitlab::Ci::Build::Image.from_services(self)
    end

    def cache
      cache = options[:cache]

      if cache && project.jobs_cache_index
        cache = cache.merge(
          key: "#{cache[:key]}-#{project.jobs_cache_index}")
      end

      [cache]
    end

    def credentials
      Gitlab::Ci::Build::Credentials::Factory.new(self).create!
    end

    def all_dependencies
      (dependencies + cross_dependencies).uniq
    end

    def dependencies
      return [] if empty_dependencies?

      depended_jobs = depends_on_builds

      # find all jobs that are needed
      if Feature.enabled?(:ci_dag_support, project, default_enabled: true) && needs.exists?
        depended_jobs = depended_jobs.where(name: needs.artifacts.select(:name))
      end

      # find all jobs that are dependent on
      if options[:dependencies].present?
        depended_jobs = depended_jobs.where(name: options[:dependencies])
      end

      # if both needs and dependencies are used,
      # the end result will be an intersection between them
      depended_jobs
    end

    def cross_dependencies
      []
    end

    def empty_dependencies?
      options[:dependencies]&.empty?
    end

    def has_valid_build_dependencies?
      return true if Feature.enabled?('ci_disable_validates_dependencies')

      dependencies.all?(&:valid_dependency?)
    end

    def valid_dependency?
      return false if artifacts_expired?
      return false if erased?

      true
    end

    def invalid_dependencies
      dependencies.reject(&:valid_dependency?)
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

    def hide_secrets(trace)
      return unless trace

      trace = trace.dup
      Gitlab::Ci::MaskSecret.mask!(trace, project.runners_token) if project
      Gitlab::Ci::MaskSecret.mask!(trace, token) if token
      trace
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
          Gitlab::Ci::Parsers.fabricate!(file_type).parse!(blob, test_suite)
        end
      end
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

    private

    def build_data
      @build_data ||= Gitlab::DataBuilder::Build.build(self)
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
      self.update(erased_by: user, erased_at: Time.now, artifacts_expire_at: nil)
    end

    def unscoped_project
      @unscoped_project ||= Project.unscoped.find_by(id: project_id)
    end

    def environment_url
      options&.dig(:environment, :url) || persisted_environment&.external_url
    end

    # The format of the retry option changed in GitLab 11.5: Before it was
    # integer only, after it is a hash. New builds are created with the new
    # format, but builds created before GitLab 11.5 and saved in database still
    # have the old integer only format. This method returns the retry option
    # normalized as a hash in 11.5+ format.
    def options_retry
      strong_memoize(:options_retry) do
        value = options&.dig(:retry)
        value = value.is_a?(Integer) ? { max: value } : value.to_h
        value.with_indifferent_access
      end
    end
  end
end

Ci::Build.prepend_if_ee('EE::Ci::Build')
