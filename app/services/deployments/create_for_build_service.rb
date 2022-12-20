# frozen_string_literal: true

module Deployments
  # This class creates a deployment record for a build (a pipeline job).
  class CreateForBuildService
    DeploymentCreationError = Class.new(StandardError)

    def execute(build)
      return unless build.instance_of?(::Ci::Build) && build.persisted_environment.present?

      environment = build.actual_persisted_environment

      deployment = to_resource(build, environment)

      return unless deployment

      deployment.save!
      build.association(:deployment).target = deployment
      build.association(:deployment).loaded!

      deployment
    rescue ActiveRecord::RecordInvalid => e
      Gitlab::ErrorTracking.track_and_raise_for_dev_exception(
        DeploymentCreationError.new(e.message), build_id: build.id)
    end

    private

    def to_resource(build, environment)
      return build.deployment if build.deployment
      return unless build.deployment_job?

      deployment = ::Deployment.new(attributes(build, environment))

      # If there is a validation error on environment creation, such as
      # the name contains invalid character, the job will fall back to a
      # non-environment job.
      return unless deployment.valid? && deployment.environment.persisted?

      if cluster = deployment.environment.deployment_platform&.cluster
        # double write cluster_id until 12.9: https://gitlab.com/gitlab-org/gitlab/issues/202628
        deployment.cluster_id = cluster.id
        deployment.deployment_cluster = ::DeploymentCluster.new(
          cluster_id: cluster.id,
          kubernetes_namespace: cluster.kubernetes_namespace_for(deployment.environment, deployable: build)
        )
      end

      # Allocate IID for deployments.
      # This operation must be outside of transactions of pipeline creations.
      deployment.ensure_project_iid!

      deployment
    end

    def attributes(build, environment)
      {
        project: build.project,
        environment: environment,
        deployable: build,
        user: build.user,
        ref: build.ref,
        tag: build.tag,
        sha: build.sha,
        on_stop: build.on_stop
      }
    end
  end
end
