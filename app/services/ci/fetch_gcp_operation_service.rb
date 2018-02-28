module Ci
  class FetchGcpOperationService
    def execute(cluster)
      api_client =
        GoogleApi::CloudPlatform::Client.new(cluster.gcp_token, nil)

      operation = api_client.projects_zones_operations(
        cluster.gcp_project_id,
        cluster.gcp_cluster_zone,
        cluster.gcp_operation_id)

      yield(operation) if block_given?
    rescue Google::Apis::ServerError, Google::Apis::ClientError, Google::Apis::AuthorizationError => e
      return cluster.make_errored!("Failed to request to CloudPlatform; #{e.message}")
    end
  end
end
