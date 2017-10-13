module Clusters
  module Gcp
    class ProvisionService
      attr_reader :provider

      def execute(provider)
        @provider = provider

        unless operation.status == 'RUNNING' || operation.status == 'PENDING'
          return provider.make_errored!("Operation status is unexpected; #{operation.status_message}")
        end

        provider.operation_id = operation_id

        unless provider.operation_id
          return provider.make_errored!('Can not find operation_id from self_link')
        end

        if provider.make_creating
          WaitForClusterCreationWorker.perform_in(
            WaitForClusterCreationWorker::INITIAL_INTERVAL, provider.id)
        else
          return provider.make_errored!("Failed to update provider record; #{provider.errors}")
        end
      rescue Google::Apis::ServerError, Google::Apis::ClientError, Google::Apis::AuthorizationError => e
        return provider.make_errored!("Failed to request to CloudPlatform; #{e.message}")
      end

      private

      def operation_id
        api_client.parse_operation_id(operation.self_link)
      end

      def operation
        @operation ||= api_client.projects_zones_providers_create(
          provider.project_id,
          provider.provider_zone,
          provider.provider_name,
          provider.provider_size,
          machine_type: provider.machine_type)
      end

      def api_client
        provider.api_client
      end
    end
  end
end
