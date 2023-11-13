# frozen_string_literal: true

module Projects
  class UpdatePagesService < BaseService
    include Gitlab::Utils::StrongMemoize

    # old deployment can be cached by pages daemon
    # so we need to give pages daemon some time update cache
    # 10 minutes is enough, but 30 feels safer
    OLD_DEPLOYMENTS_DESTRUCTION_DELAY = 30.minutes

    attr_reader :build, :deployment_update

    def initialize(project, build)
      @project = project
      @build = build
      @deployment_update = ::Gitlab::Pages::DeploymentUpdate.new(project, build)
    end

    def execute
      register_attempt

      ::Ci::Pipelines::AddJobService.new(@build.pipeline).execute!(commit_status) do |job|
        job.enqueue!
        job.run!
      end

      return error(deployment_update.errors.first.full_message) unless deployment_update.valid?

      build.artifacts_file.use_file do |artifacts_path|
        deployment = create_pages_deployment(artifacts_path, build)

        break error('The uploaded artifact size does not match the expected value') unless deployment
        break error(deployment_update.errors.first.full_message) unless deployment_update.valid?

        deactive_old_deployments(deployment)
        success
      end
    rescue StandardError => e
      error(e.message)
      raise e
    end

    private

    def success
      commit_status.success
      publish_deployed_event
      super
    end

    def error(message)
      register_failure
      log_error("Projects::UpdatePagesService: #{message}")
      commit_status.allow_failure = !deployment_update.latest?
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
        stage: 'deploy',
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
    strong_memoize_attr :commit_status
    # rubocop: enable Performance/ActiveRecordSubtransactionMethods

    def create_pages_deployment(artifacts_path, build)
      File.open(artifacts_path) do |file|
        attributes = pages_deployment_attributes(file, build)
        deployment = project.pages_deployments.build(**attributes)

        break if deployment.file.size != file.size

        deployment.tap(&:save!)
      end
    end

    # overridden on EE
    def pages_deployment_attributes(file, build)
      {
        file: file,
        file_count: deployment_update.entries_count,
        file_sha256: build.job_artifacts_archive.file_sha256,
        ci_build_id: build.id,
        root_directory: build.options[:publish]
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
  end
end

::Projects::UpdatePagesService.prepend_mod
