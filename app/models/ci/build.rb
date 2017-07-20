module Ci
  class Build < CommitStatus
    include TokenAuthenticatable
    include AfterCommitQueue
    include Presentable
    prepend EE::Build

    belongs_to :runner
    belongs_to :trigger_request
    belongs_to :erased_by, class_name: 'User'

    has_many :sourced_pipelines, class_name: Ci::Sources::Pipeline, foreign_key: :source_job_id

    has_many :deployments, as: :deployable
    has_one :last_deployment, -> { order('deployments.id DESC') }, as: :deployable, class_name: 'Deployment'

    # The "environment" field for builds is a String, and is the unexpanded name
    def persisted_environment
      @persisted_environment ||= Environment.find_by(
        name: expanded_environment_name,
        project: project
      )
    end

    serialize :options # rubocop:disable Cop/ActiveRecordSerialize
    serialize :yaml_variables, Gitlab::Serializer::Ci::Variables # rubocop:disable Cop/ActiveRecordSerialize

    delegate :name, to: :project, prefix: true

    validates :coverage, numericality: true, allow_blank: true
    validates :ref, presence: true

    scope :unstarted, ->() { where(runner_id: nil) }
    scope :ignore_failures, ->() { where(allow_failure: false) }
    scope :with_artifacts, ->() { where.not(artifacts_file: [nil, '']) }
    scope :with_artifacts_not_expired, ->() { with_artifacts.where('artifacts_expire_at IS NULL OR artifacts_expire_at > ?', Time.now) }
    scope :with_expired_artifacts, ->() { with_artifacts.where('artifacts_expire_at < ?', Time.now) }
    scope :last_month, ->() { where('created_at > ?', Date.today - 1.month) }
    scope :manual_actions, ->() { where(when: :manual, status: COMPLETED_STATUSES + [:manual]) }
    scope :codeclimate, ->() { where(name: 'codeclimate') }

    mount_uploader :artifacts_file, ArtifactUploader
    mount_uploader :artifacts_metadata, ArtifactUploader

    acts_as_taggable

    add_authentication_token_field :token

    before_save :update_artifacts_size, if: :artifacts_file_changed?
    before_save :ensure_token
    before_destroy { unscoped_project }

    after_create :execute_hooks
    after_commit :update_project_statistics_after_save, on: [:create, :update]
    after_commit :update_project_statistics, on: :destroy

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
        next if build.retries_max.zero?

        if build.retries_count < build.retries_max
          Ci::Build.retry(build, build.user)
        end
      end
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
      ExpandVariables.expand(environment, simple_variables) if environment
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

    def timeout
      project.build_timeout
    end

    # A slugified version of the build ref, suitable for inclusion in URLs and
    # domain names. Rules:
    #
    #   * Lowercased
    #   * Anything not matching [a-z0-9-] is replaced with a -
    #   * Maximum length is 63 bytes
    #   * First/Last Character is not a hyphen
    def ref_slug
      ref.to_s
          .downcase
          .gsub(/[^a-z0-9]/, '-')[0..62]
          .gsub(/(\A-+|-+\z)/, '')
    end

    # Variables whose value does not depend on environment
    def simple_variables
      variables(environment: nil)
    end

    # All variables, including those dependent on environment, which could
    # contain unexpanded variables.
    def variables(environment: persisted_environment)
      variables = predefined_variables
      variables += project.predefined_variables
      variables += pipeline.predefined_variables
      variables += runner.predefined_variables if runner
      variables += project.container_registry_variables
      variables += project.deployment_variables if has_environment?
      variables += yaml_variables
      variables += user_variables
      variables += project.group.secret_variables_for(ref, project).map(&:to_runner_variable) if project.group
      variables += secret_variables(environment: environment)
      variables += trigger_request.user_variables if trigger_request
      variables += pipeline.pipeline_schedule.job_variables if pipeline.pipeline_schedule
      variables += persisted_environment_variables if environment

      variables
    end

    def merge_request
      return @merge_request if defined?(@merge_request)

      @merge_request ||=
        begin
          merge_requests = MergeRequest.includes(:merge_request_diff)
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
      project.http_url_to_repo.sub(/^https?:\/\//) do |prefix|
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
      write_attribute(:trace, nil)
      save
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

    def artifacts?
      !artifacts_expired? && artifacts_file.exists?
    end

    def browsable_artifacts?
      artifacts_metadata?
    end

    def artifacts_metadata?
      artifacts? && artifacts_metadata.exists?
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
      return [] if user.blank?

      [
        { key: 'GITLAB_USER_ID', value: user.id.to_s, public: true },
        { key: 'GITLAB_USER_EMAIL', value: user.email, public: true }
      ]
    end

    def secret_variables(environment: persisted_environment)
      project.secret_variables_for(ref: ref, environment: environment)
        .map(&:to_runner_variable)
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
      [options[:cache]]
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

    def hide_secrets(trace)
      return unless trace

      trace = trace.dup
      Ci::MaskSecret.mask!(trace, project.runners_token) if project
      Ci::MaskSecret.mask!(trace, token)
      trace
    end

    def has_codeclimate_json?
      options.dig(:artifacts, :paths) == ['codeclimate.json'] &&
        artifacts_metadata?
    end

    private

    def update_artifacts_size
      self.artifacts_size = if artifacts_file.exists?
                              artifacts_file.size
                            else
                              nil
                            end
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

    def predefined_variables
      variables = [
        { key: 'CI', value: 'true', public: true },
        { key: 'GITLAB_CI', value: 'true', public: true },
        { key: 'CI_SERVER_NAME', value: 'GitLab', public: true },
        { key: 'CI_SERVER_VERSION', value: Gitlab::VERSION, public: true },
        { key: 'CI_SERVER_REVISION', value: Gitlab::REVISION, public: true },
        { key: 'CI_JOB_ID', value: id.to_s, public: true },
        { key: 'CI_JOB_NAME', value: name, public: true },
        { key: 'CI_JOB_STAGE', value: stage, public: true },
        { key: 'CI_JOB_TOKEN', value: token, public: false },
        { key: 'CI_COMMIT_SHA', value: sha, public: true },
        { key: 'CI_COMMIT_REF_NAME', value: ref, public: true },
        { key: 'CI_COMMIT_REF_SLUG', value: ref_slug, public: true },
        { key: 'CI_REGISTRY_USER', value: CI_REGISTRY_USER, public: true },
        { key: 'CI_REGISTRY_PASSWORD', value: token, public: false },
        { key: 'CI_REPOSITORY_URL', value: repo_url, public: false }
      ]

      variables << { key: "CI_COMMIT_TAG", value: ref, public: true } if tag?
      variables << { key: "CI_PIPELINE_TRIGGERED", value: 'true', public: true } if trigger_request
      variables << { key: "CI_JOB_MANUAL", value: 'true', public: true } if action?
      variables.concat(legacy_variables)
    end

    def persisted_environment_variables
      return [] unless persisted_environment

      variables = persisted_environment.predefined_variables

      # Here we're passing unexpanded environment_url for runner to expand,
      # and we need to make sure that CI_ENVIRONMENT_NAME and
      # CI_ENVIRONMENT_SLUG so on are available for the URL be expanded.
      variables << { key: 'CI_ENVIRONMENT_URL', value: environment_url, public: true } if environment_url

      variables
    end

    def legacy_variables
      variables = [
        { key: 'CI_BUILD_ID', value: id.to_s, public: true },
        { key: 'CI_BUILD_TOKEN', value: token, public: false },
        { key: 'CI_BUILD_REF', value: sha, public: true },
        { key: 'CI_BUILD_BEFORE_SHA', value: before_sha, public: true },
        { key: 'CI_BUILD_REF_NAME', value: ref, public: true },
        { key: 'CI_BUILD_REF_SLUG', value: ref_slug, public: true },
        { key: 'CI_BUILD_NAME', value: name, public: true },
        { key: 'CI_BUILD_STAGE', value: stage, public: true }
      ]

      variables << { key: "CI_BUILD_TAG", value: ref, public: true } if tag?
      variables << { key: "CI_BUILD_TRIGGERED", value: 'true', public: true } if trigger_request
      variables << { key: "CI_BUILD_MANUAL", value: 'true', public: true } if action?
      variables
    end

    def environment_url
      options&.dig(:environment, :url) || persisted_environment&.external_url
    end

    def build_attributes_from_config
      return {} unless pipeline.config_processor

      pipeline.config_processor.build_attributes(name)
    end

    def update_project_statistics
      return unless project

      ProjectCacheWorker.perform_async(project_id, [], [:build_artifacts_size])
    end

    def update_project_statistics_after_save
      if previous_changes.include?('artifacts_size')
        update_project_statistics
      end
    end
  end
end
