module Clusters
  module Gcp
    class FinalizeCreationService
      attr_reader :provider

      def execute(provider)
        @provider = provider

        configure_provider
        configure_kubernetes

        ActiveRecord::Base.transaction do
          kubernetes.save!
          provider.make_created!
        end
      rescue Google::Apis::ServerError, Google::Apis::ClientError, Google::Apis::AuthorizationError => e
        provider.make_errored!("Failed to request to CloudPlatform; #{e.message}")
      rescue KubeException => e
        provider.make_errored!("Failed to request to Kubernetes; #{e.message}")
      rescue ActiveRecord::RecordInvalid => e
        provider.make_errored!("Failed to configure GKE Cluster: #{e.message}")
      end

      private

      def configure_provider
        provider.endpoint = gke_cluster.endpoint
      end

      def configure_kubernetes
        kubernetes.api_url = 'https://' + gke_cluster.endpoint
        kubernetes.ca_cert = Base64.decode64(gke_cluster.master_auth.cluster_ca_certificate)
        kubernetes.username = gke_cluster.master_auth.username
        kubernetes.password = gke_cluster.master_auth.password
        kubernetes.token = request_kuberenetes_token
      end

      def request_kuberenetes_token
        kubernetes.read_secrets.each do |secret|
          name = secret.dig('metadata', 'name')
          if /default-token/ =~ name
            token_base64 = secret.dig('data', 'token')
            return Base64.decode64(token_base64) if token_base64
          end
        end

        nil
      end

      def gke_cluster
        @gke_cluster ||= provider.api_client.projects_zones_clusters_get(
          provider.gcp_project_id,
          provider.zone,
          cluster.name)
      end

      def cluster
        @cluster ||= provider.cluster
      end

      def kubernetes
        @kubernetes ||= cluster.platform_kubernetes
      end
    end
  end
end
