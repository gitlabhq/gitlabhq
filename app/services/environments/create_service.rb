# frozen_string_literal: true

module Environments
  class CreateService < BaseService
    ALLOWED_ATTRIBUTES = %i[name external_url tier cluster_agent kubernetes_namespace flux_resource_path].freeze

    def execute
      unless can?(current_user, :create_environment, project)
        return ServiceResponse.error(
          message: _('Unauthorized to create an environment'),
          payload: { environment: nil }
        )
      end

      if unauthorized_cluster_agent?
        return ServiceResponse.error(
          message: _('Unauthorized to access the cluster agent in this project'),
          payload: { environment: nil })
      end

      environment = project.environments.create(**params.slice(*ALLOWED_ATTRIBUTES))

      if environment.persisted?
        ServiceResponse.success(payload: { environment: environment })
      else
        ServiceResponse.error(
          message: environment.errors.full_messages,
          payload: { environment: nil }
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
