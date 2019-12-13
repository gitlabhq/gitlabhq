# frozen_string_literal: true

module Clusters
  class CreateService
    attr_reader :current_user, :params

    def initialize(user = nil, params = {})
      @current_user, @params = user, params.dup
    end

    def execute(access_token: nil)
      raise ArgumentError, 'Unknown clusterable provided' unless clusterable
      raise ArgumentError, _('Instance does not support multiple Kubernetes clusters') unless can_create_cluster?

      cluster_params = params.merge(user: current_user).merge(clusterable_params)
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

    def clusterable
      @clusterable ||= params.delete(:clusterable)
    end

    def clusterable_params
      case clusterable
      when ::Project
        { cluster_type: :project_type, projects: [clusterable] }
      when ::Group
        { cluster_type: :group_type, groups: [clusterable] }
      when Instance
        { cluster_type: :instance_type }
      else
        raise NotImplementedError
      end
    end

    # EE would override this method
    def can_create_cluster?
      clusterable.clusters.empty?
    end
  end
end
