# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        class CreateDeployments < Chain::Base
          DeploymentCreationError = Class.new(StandardError)

          def perform!
            return unless pipeline.create_deployment_in_separate_transaction?

            create_deployments!
          end

          def break?
            false
          end

          private

          def create_deployments!
            pipeline.stages.map(&:statuses).flatten.map(&method(:create_deployment))
          end

          def create_deployment(build)
            return unless build.instance_of?(::Ci::Build) && build.persisted_environment.present?

            deployment = ::Gitlab::Ci::Pipeline::Seed::Deployment
              .new(build, build.persisted_environment).to_resource

            return unless deployment

            deployment.deployable = build
            deployment.save!
          rescue ActiveRecord::RecordInvalid => e
            Gitlab::ErrorTracking.track_and_raise_for_dev_exception(
              DeploymentCreationError.new(e.message), build_id: build.id)
          end
        end
      end
    end
  end
end
