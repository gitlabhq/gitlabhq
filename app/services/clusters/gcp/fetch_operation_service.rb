# frozen_string_literal: true

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
        logger.error(
          exception: e.class.name,
          service: self.class.name,
          provider_id: provider.id,
          message: e.message
        )

        provider.make_errored!("Failed to request to CloudPlatform; #{e.message}")
      end

      private

      def logger
        @logger ||= Gitlab::Kubernetes::Logger.build
      end
    end
  end
end
