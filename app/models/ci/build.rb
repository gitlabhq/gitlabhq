# frozen_string_literal: true

module Ci
  class Build < CommitStatus
    prepend ArtifactMigratable
    include TokenAuthenticatable
    include AfterCommitQueue
    include ObjectStorage::BackgroundMove
    include Presentable
    include Importable
    include Gitlab::Utils::StrongMemoize

    ignore_column :environment

    belongs_to :project, inverse_of: :builds
    belongs_to :runner
    belongs_to :trigger_request
    belongs_to :erased_by, class_name: 'User'

    has_many :deployments, as: :deployable

    RUNNER_FEATURES = {
      upload_multiple_artifacts: -> (build) { build.publishes_artifacts_reports? }
    }.freeze

    has_one :last_deployment, -> { order('deployments.id DESC') }, as: :deployable, class_name: 'Deployment'
    has_many :trace_sections, class_name: 'Ci::BuildTraceSection'
    has_many :trace_chunks, class_name: 'Ci::BuildTraceChunk', foreign_key: :build_id

    has_many :job_artifacts, class_name: 'Ci::JobArtifact', foreign_key: :job_id, dependent: :destroy, inverse_of: :job # rubocop:disable Cop/ActiveRecordDependent

    Ci::JobArtifact.file_types.each do |key, value|
      has_one :"job_artifacts_#{key}", -> { where(file_type: value) }, class_name: 'Ci::JobArtifact', inverse_of: :job, foreign_key: :job_id
    end

    has_one :config, class_name: 'Ci::BuildConfig'
    has_one :metadata, class_name: 'Ci::BuildMetadata'
    has_one :environment_deployment, class_name: 'Ci::BuildEnvironmentDeployment'
    has_one :runner_session, class_name: 'Ci::BuildRunnerSession', validate: true, inverse_of: :build

    accepts_nested_attributes_for :runner_session

    delegate :timeout, to: :metadata, prefix: true, allow_nil: true
    delegate :url, to: :runner_session, prefix: true, allow_nil: true
    delegate :terminal_specification, to: :runner_session, allow_nil: true
    delegate :gitlab_deploy_token, to: :project

    delegate :name, to: :project, prefix: true

    validates :coverage, numericality: true, allow_blank: true
    validates :ref, presence: true

    scope :unstarted, ->() { where(runner_id: nil) }
    scope :ignore_failures, ->() { where(allow_failure: false) }
    scope :with_artifacts_archive, ->() do
      where('(artifacts_file IS NOT NULL AND artifacts_file <> ?) OR EXISTS (?)',
        '', Ci::JobArtifact.select(1).where('ci_builds.id = ci_job_artifacts.job_id').archive)
    end

    scope :with_archived_trace, ->() do
      where('EXISTS (?)', Ci::JobArtifact.select(1).where('ci_builds.id = ci_job_artifacts.job_id').trace)
    end

    scope :without_archived_trace, ->() do
      where('NOT EXISTS (?)', Ci::JobArtifact.select(1).where('ci_builds.id = ci_job_artifacts.job_id').trace)
    end

    scope :with_test_reports, ->() do
      includes(:job_artifacts_junit) # Prevent N+1 problem when iterating each ci_job_artifact row
        .where('EXISTS (?)', Ci::JobArtifact.select(1).where('ci_builds.id = ci_job_artifacts.job_id').test_reports)
    end

    scope :with_artifacts_stored_locally, -> { with_artifacts_archive.where(artifacts_file_store: [nil, LegacyArtifactUploader::Store::LOCAL]) }
    scope :with_archived_trace_stored_locally, -> { with_archived_trace.where(artifacts_file_store: [nil, LegacyArtifactUploader::Store::LOCAL]) }
    scope :with_artifacts_not_expired, ->() { with_artifacts_archive.where('artifacts_expire_at IS NULL OR artifacts_expire_at > ?', Time.now) }
    scope :with_expired_artifacts, ->() { with_artifacts_archive.where('artifacts_expire_at < ?', Time.now) }
    scope :last_month, ->() { where('created_at > ?', Date.today - 1.month) }
    scope :manual_actions, ->() { where(when: :manual, status: COMPLETED_STATUSES + [:manual]) }
    scope :ref_protected, -> { where(protected: true) }
    scope :with_live_trace, -> { where('EXISTS (?)', Ci::BuildTraceChunk.where('ci_builds.id = ci_build_trace_chunks.build_id').select(1)) }

    scope :matches_tag_ids, -> (tag_ids) do
      matcher = ::ActsAsTaggableOn::Tagging
        .where(taggable_type: CommitStatus)
        .where(context: 'tags')
        .where('taggable_id = ci_builds.id')
        .where.not(tag_id: tag_ids).select('1')

      where("NOT EXISTS (?)", matcher)
    end

    scope :with_any_tags, -> do
      matcher = ::ActsAsTaggableOn::Tagging
        .where(taggable_type: CommitStatus)
        .where(context: 'tags')
        .where('taggable_id = ci_builds.id').select('1')

      where("EXISTS (?)", matcher)
    end

    mount_uploader :legacy_artifacts_file, LegacyArtifactUploader, mount_on: :artifacts_file
    mount_uploader :legacy_artifacts_metadata, LegacyArtifactUploader, mount_on: :artifacts_metadata

    acts_as_taggable

    add_authentication_token_field :token

    before_save :update_artifacts_size, if: :artifacts_file_changed?
    before_save :ensure_token
    before_destroy { unscoped_project }

    before_create :ensure_metadata
    after_create unless: :importing? do |build|
      run_after_commit { BuildHooksWorker.perform_async(build.id) }
    end

    after_save :update_project_statistics_after_save, if: :artifacts_size_changed?
    after_destroy :update_project_statistics_after_destroy, unless: :project_destroyed?

    delegate :retries_max, :yaml_variables, :environment_action,
      :dependencies, :environment_url, to: :ensure_config

    delegate :environment, :environment_name, :deployment, :starts_environment?, :stops_environment?,
      to: :ensure_environment_deployment

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
        Ci::RetryBuildService
          .new(build.project, current_user)
          .execute(build)
      end
    end

    state_machine :status do
      event :actionize do
        transition created: :manual
      end

      after_transition any => [:pending] do |build|
        build.run_after_commit do
          BuildQueueWorker.perform_async(id)
        end
      end

      after_transition pending: :running do |build|
        build.run_after_commit do
          BuildHooksWorker.perform_async(id)
        end
      end

      after_transition any => [:success, :failed, :canceled] do |build|
        build.run_after_commit do
          BuildFinishedWorker.perform_async(id)
        end
      end

      after_transition any => [:success] do |build|
        build.run_after_commit do
          BuildSuccessWorker.perform_async(id)
          PagesWorker.perform_async(:deploy, id) if build.pages_generator?
        end
      end

      before_transition any => [:failed] do |build|
        next unless build.project
        next if build.retries_max.zero?

        if build.retries_count < build.retries_max
          begin
            Ci::Build.retry(build, build.user)
          rescue Gitlab::Access::AccessDeniedError => ex
            Rails.logger.error "Unable to auto-retry job #{build.id}: #{ex}"
          end
        end
      end

      after_transition pending: :running do |build|
        build.ensure_metadata.update_timeout_state
      end

      after_transition running: any do |build|
        Ci::BuildRunnerSession.where(build: build).delete_all
      end
    end

    def ensure_metadata
      metadata || build_metadata(project: project)
    end

    def ensure_config
      config || migrate_config
    end

    def migrate_config
      build_config.tap do |new_config|
        # assign data
        new_config.yaml_commands = self.commands
        new_config.yaml_options = self.options
        new_config.yaml_variables = self.yaml_variables

        # nullify current data (if saved, it is gonna be removed)
        self.commands = nil
        self.options = nil
        self.yaml_variables = nil
      end
    end

    def ensure_environment_deployment
      environment_deployment || migrate_environment_deployment
    end

    def migrate_environment_deployment
      environment = ensure_config.persisted_environment
      return unless environment

      build_environment_deployment(
        environment: environment,
        action: ensure_config.environment_action
      )
    end

    def detailed_status(current_user)
      Gitlab::Ci::Status::Build::Factory
        .new(self, current_user)
        .fabricate!
    end

    def other_actions
      pipeline.manual_actions.where.not(name: name)
    end

    def pages_generator?
      Gitlab.config.pages.enabled &&
        self.name == 'pages'
    end

    def playable?
      action? && (manual? || retryable?)
    end

    def action?
      self.when == 'manual'
    end

    def play(current_user)
      Ci::PlayBuildService
        .new(project, current_user)
        .execute(self)
    end

    def cancelable?
      active? || created?
    end

    def retryable?
      success? || failed? || canceled?
    end

    def retries_count
      pipeline.builds.retried.where(name: self.name).count
    end

    def latest?
      !retried?
    end

    def has_environment?
      ensure_environment_deployment.present?
    end

    def starts_environment?
      ensure_environment_deployment&.start?
    end

    def stops_environment?
      ensure_environment_deployment&.stop?
    end

    def outdated_deployment?
      ensure_environment_deployment&.outdated?
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

    # A slugified version of the build ref, suitable for inclusion in URLs and
    # domain names. Rules:
    #
    #   * Lowercased
    #   * Anything not matching [a-z0-9-] is replaced with a -
    #   * Maximum length is 63 bytes
    #   * First/Last Character is not a hyphen
    def ref_slug
      Gitlab::Utils.slugify(ref.to_s)
    end

    ##
    # Variables in the environment name scope.
    #
    def scoped_variables(environment: environment_name)
      Gitlab::Ci::Variables::Collection.new.tap do |variables|
        variables.concat(predefined_variables)
        variables.concat(project.predefined_variables)
        variables.concat(pipeline.predefined_variables)
        variables.concat(runner.predefined_variables) if runner
        variables.concat(project.deployment_variables(environment: environment)) if environment
        variables.concat(yaml_variables)
        variables.concat(user_variables)
        variables.concat(secret_group_variables)
        variables.concat(secret_project_variables(environment: environment))
        variables.concat(trigger_request.user_variables) if trigger_request
        variables.concat(pipeline.variables)
        variables.concat(pipeline.pipeline_schedule.job_variables) if pipeline.pipeline_schedule
      end
    end

    ##
    # Variables that do not depend on the environment name.
    #
    def simple_variables
      strong_memoize(:simple_variables) do
        scoped_variables(environment: nil).to_runner_variables
      end
    end

    ##
    # All variables, including persisted environment variables.
    #
    def variables
      Gitlab::Ci::Variables::Collection.new
        .concat(persisted_variables)
        .concat(scoped_variables)
        .concat(persisted_environment_variables)
        .to_runner_variables
    end

    ##
    # Regular Ruby hash of scoped variables, without duplicates that are
    # possible to be present in an array of hashes returned from `variables`.
    #
    def scoped_variables_hash
      scoped_variables.to_hash
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
      auth = "gitlab-ci-token:#{ensure_token!}@"
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

    def parse_trace_sections!
      ExtractSectionsFromBuildTraceService.new(project, user).execute(self)
    end

    def trace
      Gitlab::Ci::Trace.new(self)
    end

    def has_trace?
      trace.exist?
    end

    def has_test_reports?
      job_artifacts.test_reports.any?
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

    def needs_touch?
      Time.now - updated_at > 15.minutes.to_i
    end

    def valid_token?(token)
      self.token && ActiveSupport::SecurityUtils.variable_size_secure_compare(token, self.token)
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

      build_data = Gitlab::DataBuilder::Build.build(self)
      project.execute_hooks(build_data.dup, :job_hooks)
      project.execute_services(build_data.dup, :job_hooks)
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

    def erase_artifacts!
      remove_artifacts_file!
      remove_artifacts_metadata!
      save
    end

    def erase_test_reports!
      # TODO: Use fast_destroy_all in the context of https://gitlab.com/gitlab-org/gitlab-ce/issues/35240
      job_artifacts_junit&.destroy
    end

    def erase(opts = {})
      return false unless erasable?

      erase_artifacts!
      erase_test_reports!
      erase_trace!
      update_erased!(opts[:erased_by])
    end

    def erasable?
      complete? && (artifacts? || has_test_reports? || has_trace?)
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

    def coverage_regex
      super || project.try(:build_coverage_regex)
    end

    def when
      read_attribute(:when) || 'on_success'
    end

    def yaml_variables
      read_attribute(:yaml_variables) || []
    end

    def user_variables
      Gitlab::Ci::Variables::Collection.new.tap do |variables|
        break variables if user.blank?

        variables.append(key: 'GITLAB_USER_ID', value: user.id.to_s)
        variables.append(key: 'GITLAB_USER_EMAIL', value: user.email)
        variables.append(key: 'GITLAB_USER_LOGIN', value: user.username)
        variables.append(key: 'GITLAB_USER_NAME', value: user.name)
      end
    end

    def secret_group_variables
      return [] unless project.group

      project.group.secret_variables_for(ref, project)
    end

    def secret_project_variables(environment: persisted_environment)
      project.secret_variables_for(ref: ref, environment: environment)
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
      Gitlab::Ci::MaskSecret.mask!(trace, token)
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
        each_test_report do |file_type, blob|
          Gitlab::Ci::Parsers.fabricate!(file_type).parse!(blob, test_suite)
        end
      end
    end

    private

    def each_test_report
      Ci::JobArtifact::TEST_REPORT_FILE_TYPES.each do |file_type|
        public_send("job_artifacts_#{file_type}").each_blob do |blob| # rubocop:disable GitlabSecurity/PublicSend
          yield file_type, blob
        end
      end
    end

    def update_artifacts_size
      self.artifacts_size = legacy_artifacts_file&.size
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

    CI_REGISTRY_USER = 'gitlab-ci-token'.freeze

    def persisted_variables
      Gitlab::Ci::Variables::Collection.new.tap do |variables|
        break variables unless persisted?

        variables
          .concat(pipeline.persisted_variables)
          .append(key: 'CI_JOB_ID', value: id.to_s)
          .append(key: 'CI_JOB_URL', value: Gitlab::Routing.url_helpers.project_job_url(project, self))
          .append(key: 'CI_JOB_TOKEN', value: token, public: false)
          .append(key: 'CI_BUILD_ID', value: id.to_s)
          .append(key: 'CI_BUILD_TOKEN', value: token, public: false)
          .append(key: 'CI_REGISTRY_USER', value: CI_REGISTRY_USER)
          .append(key: 'CI_REGISTRY_PASSWORD', value: token, public: false)
          .append(key: 'CI_REPOSITORY_URL', value: repo_url, public: false)
          .concat(deploy_token_variables)
      end
    end

    def predefined_variables
      Gitlab::Ci::Variables::Collection.new.tap do |variables|
        variables.append(key: 'CI', value: 'true')
        variables.append(key: 'GITLAB_CI', value: 'true')
        variables.append(key: 'GITLAB_FEATURES', value: project.licensed_features.join(','))
        variables.append(key: 'CI_SERVER_NAME', value: 'GitLab')
        variables.append(key: 'CI_SERVER_VERSION', value: Gitlab::VERSION)
        variables.append(key: 'CI_SERVER_REVISION', value: Gitlab.revision)
        variables.append(key: 'CI_JOB_NAME', value: name)
        variables.append(key: 'CI_JOB_STAGE', value: stage)
        variables.append(key: 'CI_COMMIT_SHA', value: sha)
        variables.append(key: 'CI_COMMIT_BEFORE_SHA', value: before_sha)
        variables.append(key: 'CI_COMMIT_REF_NAME', value: ref)
        variables.append(key: 'CI_COMMIT_REF_SLUG', value: ref_slug)
        variables.append(key: "CI_COMMIT_TAG", value: ref) if tag?
        variables.append(key: "CI_PIPELINE_TRIGGERED", value: 'true') if trigger_request
        variables.append(key: "CI_JOB_MANUAL", value: 'true') if action?
        variables.concat(legacy_variables)
      end
    end

    def legacy_variables
      Gitlab::Ci::Variables::Collection.new.tap do |variables|
        variables.append(key: 'CI_BUILD_REF', value: sha)
        variables.append(key: 'CI_BUILD_BEFORE_SHA', value: before_sha)
        variables.append(key: 'CI_BUILD_REF_NAME', value: ref)
        variables.append(key: 'CI_BUILD_REF_SLUG', value: ref_slug)
        variables.append(key: 'CI_BUILD_NAME', value: name)
        variables.append(key: 'CI_BUILD_STAGE', value: stage)
        variables.append(key: "CI_BUILD_TAG", value: ref) if tag?
        variables.append(key: "CI_BUILD_TRIGGERED", value: 'true') if trigger_request
        variables.append(key: "CI_BUILD_MANUAL", value: 'true') if action?
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
        variables.append(key: 'CI_DEPLOY_PASSWORD', value: gitlab_deploy_token.token, public: false)
      end
    end

    def update_project_statistics_after_save
      update_project_statistics(read_attribute(:artifacts_size).to_i - artifacts_size_was.to_i)
    end

    def update_project_statistics_after_destroy
      update_project_statistics(-artifacts_size)
    end

    def update_project_statistics(difference)
      ProjectStatistics.increment_statistic(project_id, :build_artifacts_size, difference)
    end

    def project_destroyed?
      project.pending_delete?
    end
  end
end
