module Clusters
  class CreateService < BaseService
    attr_reader :access_token

    TEMPOLARY_API_URL = 'http://tempolary_api_url'.freeze
    TEMPOLARY_TOKEN = 'tempolary_token'.freeze

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

      params[:provider_gcp_attributes].try do |provider|
        provider[:access_token] = access_token

        params[:platform_kubernetes_attributes].try do |platform|
          platform[:api_url] = TEMPOLARY_API_URL
          platform[:token] = TEMPOLARY_TOKEN
        end
      end

      @cluster_params = params.merge(user: current_user)
    end
  end
end
