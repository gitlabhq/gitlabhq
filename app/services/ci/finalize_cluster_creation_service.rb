module Ci
  class FinalizeClusterCreationService
    def execute(cluster)
      api_client =
        GoogleApi::CloudPlatform::Client.new(cluster.gcp_token, nil)

      begin
        gke_cluster = api_client.projects_zones_clusters_get(
          cluster.gcp_project_id,
          cluster.gcp_cluster_zone,
          cluster.gcp_cluster_name)
      rescue Google::Apis::ServerError, Google::Apis::ClientError, Google::Apis::AuthorizationError => e
        return cluster.make_errored!("Failed to request to CloudPlatform; #{e.message}")
      end

      endpoint = gke_cluster.endpoint
      api_url = 'https://' + endpoint
      ca_cert = Base64.decode64(gke_cluster.master_auth.cluster_ca_certificate)
      username = gke_cluster.master_auth.username
      password = gke_cluster.master_auth.password

      kubernetes_token = Ci::FetchKubernetesTokenService.new(
        api_url, ca_cert, username, password).execute

      unless kubernetes_token
        return cluster.make_errored!('Failed to get a default token of kubernetes')
      end

      Ci::IntegrateClusterService.new.execute(
        cluster, endpoint, ca_cert, kubernetes_token, username, password)
    end
  end
end
