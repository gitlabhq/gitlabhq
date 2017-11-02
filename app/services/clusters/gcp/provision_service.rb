module Clusters
  module Gcp
    class ProvisionService
      attr_reader :provider

      def execute(provider)
        @provider = provider

        get_operation_id do |operation_id|
          if provider.make_creating(operation_id)
            WaitForClusterCreationWorker.perform_in(
              Clusters::Gcp::VerifyProvisionStatusService::INITIAL_INTERVAL,
              provider.cluster_id)
          else
            provider.make_errored!("Failed to update provider record; #{provider.errors}")
          end
        end
      end

      private

      def get_operation_id
        operation = provider.api_client.projects_zones_clusters_create(
          provider.gcp_project_id,
          provider.zone,
          provider.cluster.name,
          provider.num_nodes,
          machine_type: provider.machine_type)

        unless operation.status == 'PENDING' || operation.status == 'RUNNING'
          return provider.make_errored!("Operation status is unexpected; #{operation.status_message}")
        end

        operation_id = provider.api_client.parse_operation_id(operation.self_link)

        unless operation_id
          return provider.make_errored!('Can not find operation_id from self_link')
        end

        yield(operation_id)

      rescue Google::Apis::ServerError, Google::Apis::ClientError, Google::Apis::AuthorizationError => e
        provider.make_errored!("Failed to request to CloudPlatform; #{e.message}")
      end
    end
  end
end
