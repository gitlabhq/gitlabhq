# frozen_string_literal: true

module Ci
  module Deployments
    class DestroyService < BaseService
      def execute(deployment)
        raise Gitlab::Access::AccessDeniedError unless can?(current_user, :destroy_deployment, deployment)

        return ServiceResponse.error(message: 'Cannot destroy running deployment') if deployment&.running?
        return ServiceResponse.error(message: 'Deployment currently deployed to environment') if deployment&.last?

        project.destroy_deployment_by_id(deployment)

        ServiceResponse.success(message: 'Deployment destroyed')
      end
    end
  end
end
