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
      cluster = nil

      ActiveRecord::Base.transaction do
        cluster = Clusters::Cluster.create!(cluster_params)
        cluster.projects << project
      end

      cluster
    rescue ActiveRecord::RecordInvalid => e
      e.record
    end

    def cluster_params
      return @cluster_params if defined?(@cluster_params)

      params[:provider_gcp_attributes].try do |h|
        h[:access_token] = access_token
      end

      @cluster_params = params.merge(user: current_user)
    end
  end
end
