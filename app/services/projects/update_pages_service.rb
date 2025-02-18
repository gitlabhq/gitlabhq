# frozen_string_literal: true

module Projects
  class UpdatePagesService < BaseService
    include Gitlab::InternalEventsTracking
    include Gitlab::Utils::StrongMemoize

    # old deployment can be cached by pages daemon
    # so we need to give pages daemon some time update cache
    # 10 minutes is enough, but 30 feels safer
    OLD_DEPLOYMENTS_DESTRUCTION_DELAY = 30.minutes

    attr_reader :build, :deployment_validations

    def initialize(project, build)
      @project = project
      @build = build
      @deployment_validations = ::Gitlab::Pages::DeploymentValidations.new(project, build)
    end

    def execute
      register_attempt

      ::Ci::Pipelines::AddJobService.new(@build.pipeline).execute!(commit_status) do |job|
        job.enqueue!
        job.run!
      end

      return error(deployment_validations.errors.first.full_message) unless deployment_validations.valid?

      handle_deployment_with_open_file
    rescue StandardError => e
      error(e.message)
      raise e
    end

    private

    def config
      build.pages.is_a?(Hash) ? build.pages : {}
    end

    def extra_deployment?
      path_prefix.present?
    end

    def url_builder
      @url_builder ||= ::Gitlab::Pages::UrlBuilder.new(project, config)
    end

    def path_prefix
      url_builder.path_prefix
    end

    def success
      commit_status.success
      publish_deployed_event
      super
    end

    def error(message)
      register_failure
      log_error("Projects::UpdatePagesService: #{message}")
      commit_status.allow_failure = !deployment_validations.latest_build?
      commit_status.description = message
      commit_status.drop(:script_failure)
      super
    end

    # Create status notifying the deployment of pages
    def commit_status
      GenericCommitStatus.new(
        user: build.user,
        ci_stage: stage,
        name: 'pages:deploy',
        stage_idx: stage.position
      )
    end
    strong_memoize_attr :commit_status

    # rubocop: disable Performance/ActiveRecordSubtransactionMethods
    def stage
      build.pipeline.stages.safe_find_or_create_by(name: 'deploy', pipeline_id: build.pipeline.id) do |stage|
        stage.position = GenericCommitStatus::EXTERNAL_STAGE_IDX
        stage.project = build.project
      end
    end
    strong_memoize_attr :stage
    # rubocop: enable Performance/ActiveRecordSubtransactionMethods

    def create_pages_deployment(file, build)
      attributes = pages_deployment_attributes(file, build)
      deployment = project.pages_deployments.build(**attributes)

      return if deployment.file.size != file.size

      deployment.tap(&:save!)
    end

    # overridden on EE
    def pages_deployment_attributes(file, build)
      {
        file: file,
        file_count: deployment_validations.entries_count,
        file_sha256: build.job_artifacts_archive.file_sha256,
        ci_build_id: build.id,
        root_directory: build.pages[:publish]
      }
    end

    def deactive_old_deployments(deployment)
      PagesDeployment.deactivate_deployments_older_than(
        deployment,
        time: OLD_DEPLOYMENTS_DESTRUCTION_DELAY.from_now)
    end

    def register_attempt
      pages_deployments_total_counter.increment
    end

    def register_failure
      pages_deployments_failed_total_counter.increment
    end

    def pages_deployments_total_counter
      Gitlab::Metrics.counter(:pages_deployments_total, "Counter of GitLab Pages deployments triggered")
    end
    strong_memoize_attr :pages_deployments_total_counter

    def pages_deployments_failed_total_counter
      Gitlab::Metrics.counter(:pages_deployments_failed_total, "Counter of GitLab Pages deployments which failed")
    end
    strong_memoize_attr :pages_deployments_failed_total_counter

    def publish_deployed_event
      event = ::Pages::PageDeployedEvent.new(data: {
        project_id: project.id,
        namespace_id: project.namespace_id,
        root_namespace_id: project.root_namespace.id
      })

      Gitlab::EventStore.publish(event)
    end

    def handle_deployment_with_open_file
      build.artifacts_file.use_open_file(unlink_early: false) do |file|
        handle_deployment(file)
      end
    end

    def handle_deployment(file)
      deployment = create_pages_deployment(file, build)

      return error('The uploaded artifact size does not match the expected value') unless deployment
      return error(deployment_validations.errors.first.full_message) unless deployment_validations.valid?

      track_deployment_events

      deactive_old_deployments(deployment)
      success
    end

    def track_deployment_events
      track_internal_event(
        'create_pages_deployment',
        project: project,
        namespace: project.namespace,
        user: build.user
      )

      return unless extra_deployment?

      track_internal_event(
        'create_pages_extra_deployment',
        project: project,
        namespace: project.namespace,
        user: build.user
      )
    end
  end
end

::Projects::UpdatePagesService.prepend_mod
