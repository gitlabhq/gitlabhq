module Ci
  class CreateClusterService < BaseService
    def execute(access_token)
      params['gcp_machine_type'] ||= GoogleApi::CloudPlatform::Client::DEFAULT_MACHINE_TYPE

      project.create_cluster(
        params.merge(user: current_user,
                     status: Gcp::Cluster.statuses[:scheduled],
                     gcp_token: access_token)).tap do |cluster|
        ClusterCreationWorker.perform_async(cluster.id) if cluster.persisted?
      end
    end
  end
end
