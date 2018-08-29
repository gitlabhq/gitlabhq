# frozen_string_literal: true

module Clusters
  module Gcp
    class FinalizeCreationService
      attr_reader :provider

      def execute(provider)
        @provider = provider

        create_gitlab_service_account!

        configure_provider
        configure_kubernetes

        cluster.save!
      rescue Google::Apis::ServerError, Google::Apis::ClientError, Google::Apis::AuthorizationError => e
        provider.make_errored!("Failed to request to CloudPlatform; #{e.message}")
      rescue Kubeclient::HttpError => e
        provider.make_errored!("Failed to run Kubeclient: #{e.message}")
      rescue ActiveRecord::RecordInvalid => e
        provider.make_errored!("Failed to configure Google Kubernetes Engine Cluster: #{e.message}")
      end

      private

      def create_gitlab_service_account!
        Clusters::Gcp::Kubernetes::CreateServiceAccountService.new(
          'https://' + gke_cluster.endpoint,
          Base64.decode64(gke_cluster.master_auth.cluster_ca_certificate),
          gke_cluster.master_auth.username,
          gke_cluster.master_auth.password).execute
      end

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
          authorization_type: authorization_type,
          token: request_kubernetes_token)
      end

      def request_kubernetes_token
        Clusters::Gcp::Kubernetes::FetchKubernetesTokenService.new(
          'https://' + gke_cluster.endpoint,
          Base64.decode64(gke_cluster.master_auth.cluster_ca_certificate),
          gke_cluster.master_auth.username,
          gke_cluster.master_auth.password).execute
      end

      # GKE Clusters have RBAC enabled on Kubernetes >= 1.6
      def authorization_type
        'rbac'
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
