# frozen_string_literal: true

module Clusters
  class UpdateService
    attr_reader :current_user, :params

    def initialize(user = nil, params = {})
      @current_user = user
      @params = params.dup
    end

    def execute(cluster)
      if validate_params(cluster)
        token = params.dig(:platform_kubernetes_attributes, :token)

        if token.blank?
          params[:platform_kubernetes_attributes]&.delete(:token)
        end

        cluster.update(params)
      else
        false
      end
    end

    private

    def validate_params(cluster)
      ::Clusters::Management::ValidateManagementProjectPermissionsService.new(current_user)
        .execute(cluster, params[:management_project_id])
    end
  end
end
