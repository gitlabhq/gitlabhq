module Clusters
  class CreateService < BaseService
    attr_reader :access_token

    def execute(access_token)
      @access_token = access_token

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
  end
end
