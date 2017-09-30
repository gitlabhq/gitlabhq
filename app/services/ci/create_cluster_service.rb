module Ci
  class CreateClusterService < BaseService
    def execute(access_token)
      project.clusters.create(
        params.merge(user: current_user,
                     status: Ci::Cluster.statuses[:scheduled],
                     gcp_token: access_token))
    end
  end
end
