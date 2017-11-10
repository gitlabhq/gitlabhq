module Clusters
  module Gcp
    class FetchOperationService
      def execute(provider)
        operation = provider.api_client.projects_zones_operations(
          provider.gcp_project_id,
          provider.zone,
          provider.operation_id)

        yield(operation) if block_given?
      rescue Google::Apis::ServerError, Google::Apis::ClientError, Google::Apis::AuthorizationError => e
        provider.make_errored!("Failed to request to CloudPlatform; #{e.message}")
      end
    end
  end
end
