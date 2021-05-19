# frozen_string_literal: true

module Clusters
  class IntegrationsController < ::Clusters::BaseController
    before_action :cluster
    before_action :authorize_admin_cluster!, only: [:create_or_update]

    def create_or_update
      service_response = Clusters::Integrations::CreateService
        .new(container: clusterable, cluster: cluster, current_user: current_user, params: cluster_integration_params)
        .execute

      if service_response.success?
        redirect_to cluster.show_path(params: { tab: 'integrations' }), notice: service_response.message
      else
        redirect_to cluster.show_path(params: { tab: 'integrations' }), alert: service_response.message
      end
    end

    private

    def clusterable
      raise NotImplementedError
    end

    def cluster_integration_params
      params.permit(integration: [:enabled, :application_type]).require(:integration)
    end

    def cluster
      @cluster ||= clusterable.clusters.find(params[:cluster_id]).present(current_user: current_user)
    end
  end
end
