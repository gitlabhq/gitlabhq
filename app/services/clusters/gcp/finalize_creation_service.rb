module Clusters
  module Gcp
    class FinalizeCreationService
      attr_reader :provider

      def execute(provider)
        @provider = provider

        configure_provider
        configure_kubernetes_platform
        request_kuberenetes_platform_token

        ActiveRecord::Base.transaction do
          kubernetes_platform.update!
          provider.make_created!
        end
      rescue Google::Apis::ServerError, Google::Apis::ClientError, Google::Apis::AuthorizationError => e
        return cluster.make_errored!("Failed to request to CloudPlatform; #{e.message}")
      rescue ActiveRecord::RecordInvalid => e
        cluster.make_errored!("Failed to configure GKE Cluster: #{e.message}")
      end

      private

      def configure_provider
        provider.endpoint = gke_cluster.endpoint
      end

      def configure_kubernetes_platform
        kubernetes_platform = cluster.kubernetes_platform
        kubernetes_platform.api_url = 'https://' + endpoint
        kubernetes_platform.ca_cert = Base64.decode64(gke_cluster.master_auth.cluster_ca_certificate)
        kubernetes_platform.username = gke_cluster.master_auth.username
        kubernetes_platform.password = gke_cluster.master_auth.password
      end

      def request_kuberenetes_platform_token
        kubernetes_platform.read_secrets.each do |secret|
          name = secret.dig('metadata', 'name')
          if /default-token/ =~ name
            token_base64 = secret.dig('data', 'token')
            if token_base64
              kubernetes_platform.token = Base64.decode64(token_base64)
              break
            end
          end
        end
      end

      def gke_cluster
        @gke_cluster ||= provider.api_client.projects_zones_clusters_get(
          provider.gcp_project_id,
          provider.gcp_cluster_zone,
          provider.gcp_cluster_name)
      end

      def cluster
        provider.cluster
      end

      def kubernetes_platform
        cluster.kubernetes_platform
      end
    end
  end
end
