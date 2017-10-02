module Ci
  class CreateClusterService < BaseService
    def execute(access_token)
      if params['machine_type'].blank?
        params['machine_type'] = GoogleApi::CloudPlatform::Client::DEFAULT_MACHINE_TYPE
      end

      project.create_cluster(
        params.merge(user: current_user,
                     status: Gcp::Cluster.statuses[:scheduled],
                     gcp_token: access_token))
    end
  end
end
