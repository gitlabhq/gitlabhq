module Ci
  class CreateClusterService < BaseService
    UnexpectedOperationError = Class.new(StandardError)

    def create_cluster_on_gke(api_client)
      # Create a cluster on GKE
      operation = api_client.projects_zones_clusters_create(
        params['gcp_project_id'], params['cluster_zone'], params['cluster_name'],
        cluster_size: params['cluster_size'], machine_type: params['machine_type']
      )

      if operation&.status != ('RUNNING' || 'PENDING')
        raise UnexpectedOperationError
      end

      api_client.parse_self_link(operation.self_link).tap do |project_id, zone, operation_id|
        project.clusters.create(owner: current_user,
                                gcp_project_id: params['gcp_project_id'],
                                cluster_zone: params['cluster_zone'],
                                cluster_name: params['cluster_name'],
                                project_namespace: params['project_namespace'],
                                gcp_operation_id: operation_id).tap do |cluster|
          # Start status polling. When the operation finish, create KubernetesService.
          cluster.creation_status(api_client.access_token)
        end
      end
    end
  end
end
