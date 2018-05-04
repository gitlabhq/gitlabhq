module Clusters
  module Gcp
    class FinalizeCreationService
      attr_reader :provider

      def execute(provider)
        @provider = provider

        configure_provider
        configure_kubernetes

        cluster.save!
      rescue Google::Apis::ServerError, Google::Apis::ClientError, Google::Apis::AuthorizationError => e
        provider.make_errored!("Failed to request to CloudPlatform; #{e.message}")
      rescue ActiveRecord::RecordInvalid => e
        provider.make_errored!("Failed to configure Google Kubernetes Engine Cluster: #{e.message}")
      end

      private

      def configure_provider
        provider.endpoint = gke_cluster.endpoint
        provider.status_event = :make_created
      end

      def configure_kubernetes
        cluster.platform_type = :kubernetes
        cluster.build_platform_kubernetes(
          api_url: 'https://' + gke_cluster.endpoint,
          ca_cert: Base64.decode64(gke_cluster.master_auth.cluster_ca_certificate),
          username: gke_cluster.master_auth.username,
          password: gke_cluster.master_auth.password,
          token: request_kubernetes_token)
      end

      def request_kubernetes_token
        Ci::FetchKubernetesTokenService.new(
          'https://' + gke_cluster.endpoint,
          Base64.decode64(gke_cluster.master_auth.cluster_ca_certificate),
          gke_cluster.master_auth.username,
          gke_cluster.master_auth.password).execute
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
    end
  end
end
