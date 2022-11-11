# frozen_string_literal: true

module Deployments
  # This class creates a deployment record for a build (a pipeline job).
  class CreateForBuildService
    DeploymentCreationError = Class.new(StandardError)

    def execute(build)
      return unless build.instance_of?(::Ci::Build) && build.persisted_environment.present?

      # TODO: Move all buisness logic in `Seed::Deployment` to this class after
      # `create_deployment_in_separate_transaction` feature flag has been removed.
      # See https://gitlab.com/gitlab-org/gitlab/-/issues/348778

      environment = build.actual_persisted_environment

      deployment = ::Gitlab::Ci::Pipeline::Seed::Deployment
        .new(build, environment).to_resource

      return unless deployment

      build.create_deployment!(deployment.attributes)
    rescue ActiveRecord::RecordInvalid => e
      Gitlab::ErrorTracking.track_and_raise_for_dev_exception(
        DeploymentCreationError.new(e.message), build_id: build.id)
    end
  end
end
