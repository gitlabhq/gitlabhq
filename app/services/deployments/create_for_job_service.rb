# frozen_string_literal: true

module Deployments
  # This class creates a deployment record for a pipeline job.
  class CreateForJobService
    DeploymentCreationError = Class.new(StandardError)

    def execute(job)
      return unless job.is_a?(::Ci::Processable) && job.persisted_environment.present?

      environment = job.actual_persisted_environment

      deployment = to_resource(job, environment)

      return unless deployment

      deployment.save!
      job.association(:deployment).target = deployment
      job.association(:deployment).loaded!

      deployment
    rescue ActiveRecord::RecordInvalid => e
      Gitlab::ErrorTracking.track_and_raise_for_dev_exception(
        DeploymentCreationError.new(e.message), job_id: job.id)
    end

    private

    def to_resource(job, environment)
      return job.deployment if job.deployment
      return unless job.deployment_job?

      deployment = ::Deployment.new(attributes(job, environment))

      # If there is a validation error on environment creation, such as
      # the name contains invalid character, the job will fall back to a
      # non-environment job.
      return unless deployment.valid? && deployment.environment.persisted?

      if cluster = deployment.environment.deployment_platform&.cluster # rubocop: disable Lint/AssignmentInCondition
        deployment.deployment_cluster = ::DeploymentCluster.new(
          cluster_id: cluster.id,
          kubernetes_namespace: cluster.kubernetes_namespace_for(deployment.environment, deployable: job)
        )
      end

      # Allocate IID for deployments.
      # This operation must be outside of transactions of pipeline creations.
      deployment.ensure_project_iid!

      deployment
    end

    def attributes(job, environment)
      {
        project: job.project,
        environment: environment,
        deployable: job,
        user: job.user,
        ref: job.ref,
        tag: job.tag,
        sha: job.sha,
        on_stop: job.on_stop
      }
    end
  end
end
