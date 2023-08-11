# frozen_string_literal: true

module Environments
  class UpdateService < BaseService
    ALLOWED_ATTRIBUTES = %i[external_url tier cluster_agent kubernetes_namespace flux_resource_path].freeze

    def execute(environment)
      unless can?(current_user, :update_environment, environment)
        return ServiceResponse.error(
          message: _('Unauthorized to update the environment'),
          payload: { environment: environment }
        )
      end

      if unauthorized_cluster_agent?
        return ServiceResponse.error(
          message: _('Unauthorized to access the cluster agent in this project'),
          payload: { environment: environment })
      end

      if environment.update(**params.slice(*ALLOWED_ATTRIBUTES))
        ServiceResponse.success(payload: { environment: environment })
      else
        ServiceResponse.error(
          message: environment.errors.full_messages,
          payload: { environment: environment }
        )
      end
    end

    private

    def unauthorized_cluster_agent?
      return false unless params[:cluster_agent]

      ::Clusters::Agents::Authorizations::UserAccess::Finder
        .new(current_user, agent: params[:cluster_agent], project: project)
        .execute
        .empty?
    end
  end
end
