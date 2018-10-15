# frozen_string_literal: true

class DeploymentStatusEntity < Grape::Entity
  include RequestAwareEntity

  expose :deployment_status, as: :status, if: -> (status, _) { status.has_deployments? }
  expose :environment, with: EnvironmentEntity, if: -> (status, _) { status.has_deployments? }
end
