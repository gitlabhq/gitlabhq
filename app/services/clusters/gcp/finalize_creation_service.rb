# frozen_string_literal: true

module Clusters
  module Gcp
    class FinalizeCreationService
      attr_reader :provider

      def execute(provider)
        @provider = provider

        configure_provider
        create_gitlab_service_account!
        configure_kubernetes
        configure_pre_installed_knative if provider.knative_pre_installed?
        cluster.save!
      rescue Google::Apis::ServerError, Google::Apis::ClientError, Google::Apis::AuthorizationError => e
        log_service_error(e.class.name, provider.id, e.message)
        provider.make_errored!(s_('ClusterIntegration|Failed to request to Google Cloud Platform: %{message}') % { message: e.message })
      rescue Kubeclient::HttpError => e
        log_service_error(e.class.name, provider.id, e.message)
        provider.make_errored!(s_('ClusterIntegration|Failed to run Kubeclient: %{message}') % { message: e.message })
      rescue ActiveRecord::RecordInvalid => e
        log_service_error(e.class.name, provider.id, e.message)
        provider.make_errored!(s_('ClusterIntegration|Failed to configure Google Kubernetes Engine Cluster: %{message}') % { message: e.message })
      end

      private

      def create_gitlab_service_account!
        Clusters::Kubernetes::CreateOrUpdateServiceAccountService.gitlab_creator(
          kube_client,
          rbac: create_rbac_cluster?
        ).execute
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
          authorization_type: authorization_type,
          token: request_kubernetes_token)
      end

      def configure_pre_installed_knative
        knative = cluster.build_application_knative(
          hostname: 'example.com'
        )
        knative.make_pre_installed!
      end

      def request_kubernetes_token
        Clusters::Kubernetes::FetchKubernetesTokenService.new(
          kube_client,
          Clusters::Kubernetes::GITLAB_ADMIN_TOKEN_NAME,
          Clusters::Kubernetes::GITLAB_SERVICE_ACCOUNT_NAMESPACE
        ).execute
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
          Base64.decode64(gke_cluster.master_auth.cluster_ca_certificate)
        )
      end

      def build_kube_client!(api_url, ca_pem)
        raise "Incomplete settings" unless api_url

        Gitlab::Kubernetes::KubeClient.new(
          api_url,
          auth_options: { bearer_token: provider.access_token },
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

      def logger
        @logger ||= Gitlab::Kubernetes::Logger.build
      end

      def log_service_error(exception, provider_id, message)
        logger.error(
          exception: exception.class.name,
          service: self.class.name,
          provider_id: provider_id,
          message: message
        )
      end
    end
  end
end
