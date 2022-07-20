# frozen_string_literal: true

module Projects
  class UpdatePagesService < BaseService
    # old deployment can be cached by pages daemon
    # so we need to give pages daemon some time update cache
    # 10 minutes is enough, but 30 feels safer
    OLD_DEPLOYMENTS_DESTRUCTION_DELAY = 30.minutes.freeze

    attr_reader :build, :deployment_update

    def initialize(project, build)
      @project = project
      @build = build
      @deployment_update = ::Gitlab::Pages::DeploymentUpdate.new(project, build)
    end

    def execute
      register_attempt

      # Create status notifying the deployment of pages
      @commit_status = build_commit_status
      ::Ci::Pipelines::AddJobService.new(@build.pipeline).execute!(@commit_status) do |job|
        job.enqueue!
        job.run!
      end

      return error(deployment_update.errors.first.full_message) unless deployment_update.valid?

      build.artifacts_file.use_file do |artifacts_path|
        deployment = create_pages_deployment(artifacts_path, build)

        break error('The uploaded artifact size does not match the expected value') unless deployment

        if deployment_update.valid?
          update_project_pages_deployment(deployment)
          success
        else
          error(deployment_update.errors.first.full_message)
        end
      end
    rescue StandardError => e
      error(e.message)
      raise e
    end

    private

    def success
      @commit_status.success
      @project.mark_pages_as_deployed
      publish_deployed_event
      super
    end

    def error(message)
      register_failure
      log_error("Projects::UpdatePagesService: #{message}")
      @commit_status.allow_failure = !deployment_update.latest?
      @commit_status.description = message
      @commit_status.drop(:script_failure)
      super
    end

    def build_commit_status
      GenericCommitStatus.new(
        user: build.user,
        stage: 'deploy',
        name: 'pages:deploy'
      )
    end

    def create_pages_deployment(artifacts_path, build)
      sha256 = build.job_artifacts_archive.file_sha256
      File.open(artifacts_path) do |file|
        deployment = project.pages_deployments.create!(
          file: file,
          file_count: deployment_update.entries_count,
          file_sha256: sha256,
          ci_build_id: build.id
        )

        break if deployment.size != file.size || deployment.file.size != file.size

        deployment
      end
    end

    def update_project_pages_deployment(deployment)
      project.update_pages_deployment!(deployment)
      DestroyPagesDeploymentsWorker.perform_in(
        OLD_DEPLOYMENTS_DESTRUCTION_DELAY,
        project.id,
        deployment.id
      )
    end

    def ref
      build.ref
    end

    def artifacts
      build.artifacts_file.path
    end

    def register_attempt
      pages_deployments_total_counter.increment
    end

    def register_failure
      pages_deployments_failed_total_counter.increment
    end

    def pages_deployments_total_counter
      @pages_deployments_total_counter ||= Gitlab::Metrics.counter(:pages_deployments_total, "Counter of GitLab Pages deployments triggered")
    end

    def pages_deployments_failed_total_counter
      @pages_deployments_failed_total_counter ||= Gitlab::Metrics.counter(:pages_deployments_failed_total, "Counter of GitLab Pages deployments which failed")
    end

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
