# frozen_string_literal: true

module Clusters
  class CreateService
    attr_reader :current_user, :params

    def initialize(user = nil, params = {})
      @current_user, @params = user, params.dup
    end

    def execute(project:, access_token: nil)
      raise ArgumentError, _('Instance does not support multiple Kubernetes clusters') unless can_create_cluster?(project)

      cluster_params = params.merge(user: current_user, cluster_type: :project_type, projects: [project])
      cluster_params[:provider_gcp_attributes].try do |provider|
        provider[:access_token] = access_token
      end

      create_cluster(cluster_params).tap do |cluster|
        ClusterProvisionWorker.perform_async(cluster.id) if cluster.persisted?
      end
    end

    private

    def create_cluster(cluster_params)
      Clusters::Cluster.create(cluster_params)
    end

    # EE would override this method
    def can_create_cluster?(project)
      project.clusters.empty?
    end
  end
end
