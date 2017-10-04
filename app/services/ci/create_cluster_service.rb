module Ci
  class CreateClusterService < BaseService
    def execute(access_token)
      params['gcp_machine_type'] ||= GoogleApi::CloudPlatform::Client::DEFAULT_MACHINE_TYPE

      project.create_cluster(
        params.merge(user: current_user,
                     gcp_token: access_token)).tap do |cluster|
        ClusterProvisionWorker.perform_async(cluster.id) if cluster.persisted?
      end
    end
  end
end
