module Ci
  class ProvisionClusterService
    def execute(cluster)
      api_client =
        GoogleApi::CloudPlatform::Client.new(cluster.gcp_token, nil)

      begin
        operation = api_client.projects_zones_clusters_create(
          cluster.gcp_project_id,
          cluster.gcp_cluster_zone,
          cluster.gcp_cluster_name,
          cluster.gcp_cluster_size,
          machine_type: cluster.gcp_machine_type)
      rescue Google::Apis::ServerError, Google::Apis::ClientError, Google::Apis::AuthorizationError => e
        return cluster.make_errored!("Failed to request to CloudPlatform; #{e.message}")
      end

      unless operation.status == 'RUNNING' || operation.status == 'PENDING'
        return cluster.make_errored!("Operation status is unexpected; #{operation.status_message}")
      end

      cluster.gcp_operation_id = api_client.parse_operation_id(operation.self_link)

      unless cluster.gcp_operation_id
        return cluster.make_errored!('Can not find operation_id from self_link')
      end

      if cluster.make_creating
        WaitForClusterCreationWorker.perform_in(
          WaitForClusterCreationWorker::INITIAL_INTERVAL, cluster.id)
      else
        return cluster.make_errored!("Failed to update cluster record; #{cluster.errors}")
      end
    end
  end
end
