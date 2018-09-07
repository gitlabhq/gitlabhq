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
        if create_rbac_cluster?
          Clusters::Gcp::Kubernetes::CreateServiceAccountService.new(kube_client).execute
        end
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
        service_account_name = create_rbac_cluster? ? Clusters::Gcp::Kubernetes::SERVICE_ACCOUNT_NAME : 'default'

        Clusters::Gcp::Kubernetes::FetchKubernetesTokenService.new(kube_client, service_account_name).execute
      end

      def authorization_type
        create_rbac_cluster? ? 'rbac' : 'abac'
      end

      def create_rbac_cluster?
        !provider.legacy_abac?
      end

      def kube_client
        @kube_client ||= build_kube_client!(
          'https://' + gke_cluster.endpoint,
          Base64.decode64(gke_cluster.master_auth.cluster_ca_certificate),
          gke_cluster.master_auth.username,
          gke_cluster.master_auth.password,
          api_groups: ['api', 'apis/rbac.authorization.k8s.io']
        )
      end

      def build_kube_client!(api_url, ca_pem, username, password, api_groups: ['api'], api_version: 'v1')
        raise "Incomplete settings" unless api_url && username && password

        Gitlab::Kubernetes::KubeClient.new(
          api_url,
          api_groups,
          api_version,
          auth_options: { username: username, password: password },
          ssl_options: kubeclient_ssl_options(ca_pem),
          http_proxy_uri: ENV['http_proxy']
        )
      end

      def kubeclient_ssl_options(ca_pem)
        opts = { verify_ssl: OpenSSL::SSL::VERIFY_PEER }

        if ca_pem.present?
          opts[:cert_store] = OpenSSL::X509::Store.new
          opts[:cert_store].add_cert(OpenSSL::X509::Certificate.new(ca_pem))
        end

        opts
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
