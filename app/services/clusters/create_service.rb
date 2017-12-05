module Clusters
  class CreateService < BaseService
    attr_reader :access_token

    def execute(access_token = nil)
      @access_token = access_token

      raise ArgumentError.new('Instance does not support multiple clusters') unless can_create_cluster?

      create_cluster.tap do |cluster|
        ClusterProvisionWorker.perform_async(cluster.id) if cluster.persisted?
      end
    end

    private

    def create_cluster
      Clusters::Cluster.create(cluster_params)
    end

    def cluster_params
      return @cluster_params if defined?(@cluster_params)

      params[:provider_gcp_attributes].try do |provider|
        provider[:access_token] = access_token
      end

      @cluster_params = params.merge(user: current_user, projects: [project])
    end

    def can_create_cluster?
      return true if project.clusters.empty?

      project.feature_available?(:multiple_clusters)
    end
  end
end
