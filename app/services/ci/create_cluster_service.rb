module Ci
  class CreateClusterService < BaseService
    def execute(access_token)
      params['gcp_machine_type'] ||= GoogleApi::CloudPlatform::Client::DEFAULT_MACHINE_TYPE

      cluster_params =
        params.merge(user: current_user,
                     gcp_token: access_token)

      project.create_cluster(cluster_params).tap do |cluster|
        ClusterProvisionWorker.perform_async(cluster.id) if cluster.persisted?
      end
    end
  end
end
