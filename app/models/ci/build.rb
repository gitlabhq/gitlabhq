module Ci
  class Build < CommitStatus
    prepend ArtifactMigratable
    include TokenAuthenticatable
    include AfterCommitQueue
    include ObjectStorage::BackgroundMove
    include Presentable
    include Importable
    include Gitlab::Utils::StrongMemoize

    MissingDependenciesError = Class.new(StandardError)

    belongs_to :project, inverse_of: :builds
    belongs_to :runner
    belongs_to :trigger_request
    belongs_to :erased_by, class_name: 'User'

    has_many :deployments, as: :deployable

    has_one :last_deployment, -> { order('deployments.id DESC') }, as: :deployable, class_name: 'Deployment'
    has_many :trace_sections, class_name: 'Ci::BuildTraceSection'

    has_many :job_artifacts, class_name: 'Ci::JobArtifact', foreign_key: :job_id, dependent: :destroy, inverse_of: :job # rubocop:disable Cop/ActiveRecordDependent
    has_one :job_artifacts_archive, -> { where(file_type: Ci::JobArtifact.file_types[:archive]) }, class_name: 'Ci::JobArtifact', inverse_of: :job, foreign_key: :job_id
    has_one :job_artifacts_metadata, -> { where(file_type: Ci::JobArtifact.file_types[:metadata]) }, class_name: 'Ci::JobArtifact', inverse_of: :job, foreign_key: :job_id
    has_one :job_artifacts_trace, -> { where(file_type: Ci::JobArtifact.file_types[:trace]) }, class_name: 'Ci::JobArtifact', inverse_of: :job, foreign_key: :job_id

    has_many :chunks, class_name: 'Ci::JobTraceChunk', foreign_key: :job_id

    has_one :metadata, class_name: 'Ci::BuildMetadata'
    delegate :timeout, to: :metadata, prefix: true, allow_nil: true
    delegate :gitlab_deploy_token, to: :project

    ##
    # The "environment" field for builds is a String, and is the unexpanded name!
    #
    def persisted_environment
      return unless has_environment?

      strong_memoize(:persisted_environment) do
        Environment.find_by(name: expanded_environment_name, project: project)
      end
    end

    serialize :options # rubocop:disable Cop/ActiveRecordSerialize
    serialize :yaml_variables, Gitlab::Serializer::Ci::Variables # rubocop:disable Cop/ActiveRecordSerialize

    delegate :name, to: :project, prefix: true

    validates :coverage, numericality: true, allow_blank: true
    validates :ref, presence: true

    scope :unstarted, ->() { where(runner_id: nil) }
    scope :ignore_failures, ->() { where(allow_failure: false) }
    scope :with_artifacts_archive, ->() do
      where('(artifacts_file IS NOT NULL AND artifacts_file <> ?) OR EXISTS (?)',
        '', Ci::JobArtifact.select(1).where('ci_builds.id = ci_job_artifacts.job_id').archive)
    end
    scope :with_artifacts_stored_locally, -> { with_artifacts_archive.where(artifacts_file_store: [nil, LegacyArtifactUploader::Store::LOCAL]) }
    scope :with_artifacts_not_expired, ->() { with_artifacts_archive.where('artifacts_expire_at IS NULL OR artifacts_expire_at > ?', Time.now) }
    scope :with_expired_artifacts, ->() { with_artifacts_archive.where('artifacts_expire_at < ?', Time.now) }
    scope :last_month, ->() { where('created_at > ?', Date.today - 1.month) }
    scope :manual_actions, ->() { where(when: :manual, status: COMPLETED_STATUSES + [:manual]) }
    scope :ref_protected, -> { where(protected: true) }

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

      before_transition any => [:running] do |build|
        build.validates_dependencies! unless Feature.enabled?('ci_disable_validates_dependencies')
      end

      after_transition pending: :running do |build|
        build.ensure_metadata.update_timeout_state
      end
    end

    def ensure_metadata
      metadata || build_metadata(project: project)
    end

    def detailed_status(current_user)
      Gitlab::Ci::Status::Build::Factory
        .new(self, current_user)
        .fabricate!
    end

    def other_actions
      pipeline.manual_actions.where.not(name: name)
    end

    def playable?
      action? && (manual? || complete?)
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
      active?
    end

    def retryable?
      success? || failed? || canceled?
    end

    def retries_count
      pipeline.builds.retried.where(name: self.name).count
    end

    def retries_max
      self.options.fetch(:retry, 0).to_i
    end

    def latest?
      !retried?
    end

    def expanded_environment_name
      return unless has_environment?

      strong_memoize(:expanded_environment_name) do
        ExpandVariables.expand(environment, simple_variables)
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
      success? && !last_deployment.try(:last?)
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
    def scoped_variables(environment: expanded_environment_name)
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
      update_attributes(coverage: coverage) if coverage.present?
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

    def trace=(data)
      raise NotImplementedError
    end

    def old_trace
      read_attribute(:trace)
    end

    def erase_old_trace!
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
      PagesService.new(build_data).execute
      project.running_or_pending_build_count(force: true)
    end

    def browsable_artifacts?
      artifacts_metadata?
    end

    def artifacts_metadata_entry(path, **options)
      artifacts_metadata.use_file do |metadata_path|
        metadata = Gitlab::Ci::Build::Artifacts::Metadata.new(
          metadata_path,
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

    def erase(opts = {})
      return false unless erasable?

      erase_artifacts!
      erase_trace!
      update_erased!(opts[:erased_by])
    end

    def erasable?
      complete? && (artifacts? || has_trace?)
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
      read_attribute(:when) || build_attributes_from_config[:when] || 'on_success'
    end

    def yaml_variables
      read_attribute(:yaml_variables) || build_attributes_from_config[:yaml_variables] || []
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

    def artifacts
      [options[:artifacts]]
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

    def dependencies
      return [] if empty_dependencies?

      depended_jobs = depends_on_builds

      return depended_jobs unless options[:dependencies].present?

      depended_jobs.select do |job|
        options[:dependencies].include?(job.name)
      end
    end

    def empty_dependencies?
      options[:dependencies]&.empty?
    end

    def validates_dependencies!
      dependencies.each do |dependency|
        raise MissingDependenciesError unless dependency.valid_dependency?
      end
    end

    def valid_dependency?
      return false if artifacts_expired?
      return false if erased?

      true
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

    private

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
          .append(key: 'CI_JOB_ID', value: id.to_s)
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
        variables.append(key: 'CI_SERVER_REVISION', value: Gitlab::REVISION)
        variables.append(key: 'CI_JOB_NAME', value: name)
        variables.append(key: 'CI_JOB_STAGE', value: stage)
        variables.append(key: 'CI_COMMIT_SHA', value: sha)
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

        variables.append(key: 'CI_DEPLOY_USER', value: gitlab_deploy_token.name)
        variables.append(key: 'CI_DEPLOY_PASSWORD', value: gitlab_deploy_token.token, public: false)
      end
    end

    def environment_url
      options&.dig(:environment, :url) || persisted_environment&.external_url
    end

    def build_attributes_from_config
      return {} unless pipeline.config_processor

      pipeline.config_processor.build_attributes(name)
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
