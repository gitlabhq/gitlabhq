# frozen_string_literal: true

module Clusters
  module Aws
    class FinalizeCreationService
      include Gitlab::Utils::StrongMemoize

      attr_reader :provider

      delegate :cluster, to: :provider

      def execute(provider)
        @provider = provider

        configure_provider
        create_gitlab_service_account!
        configure_platform_kubernetes
        configure_node_authentication!

        cluster.save!
      rescue ::Aws::CloudFormation::Errors::ServiceError => e
        log_service_error(e.class.name, provider.id, e.message)
        provider.make_errored!(s_('ClusterIntegration|Failed to fetch CloudFormation stack: %{message}') % { message: e.message })
      rescue Kubeclient::HttpError => e
        log_service_error(e.class.name, provider.id, e.message)
        provider.make_errored!(s_('ClusterIntegration|Failed to run Kubeclient: %{message}') % { message: e.message })
      rescue ActiveRecord::RecordInvalid => e
        log_service_error(e.class.name, provider.id, e.message)
        provider.make_errored!(s_('ClusterIntegration|Failed to configure EKS provider: %{message}') % { message: e.message })
      end

      private

      def create_gitlab_service_account!
        Clusters::Kubernetes::CreateOrUpdateServiceAccountService.gitlab_creator(
          kube_client,
          rbac: true
        ).execute
      end

      def configure_provider
        provider.status_event = :make_created
      end

      def configure_platform_kubernetes
        cluster.build_platform_kubernetes(
          api_url: cluster_endpoint,
          ca_cert: cluster_certificate,
          token: request_kubernetes_token)
      end

      def request_kubernetes_token
        Clusters::Kubernetes::FetchKubernetesTokenService.new(
          kube_client,
          Clusters::Kubernetes::GITLAB_ADMIN_TOKEN_NAME,
          Clusters::Kubernetes::GITLAB_SERVICE_ACCOUNT_NAMESPACE
        ).execute
      end

      def kube_client
        @kube_client ||= build_kube_client!(
          cluster_endpoint,
          cluster_certificate
        )
      end

      def build_kube_client!(api_url, ca_pem)
        raise "Incomplete settings" unless api_url

        Gitlab::Kubernetes::KubeClient.new(
          api_url,
          auth_options: kubeclient_auth_options,
          ssl_options: kubeclient_ssl_options(ca_pem),
          http_proxy_uri: ENV['http_proxy']
        )
      end

      def kubeclient_auth_options
        { bearer_token: Kubeclient::AmazonEksCredentials.token(provider.credentials, cluster.name) }
      end

      def kubeclient_ssl_options(ca_pem)
        opts = { verify_ssl: OpenSSL::SSL::VERIFY_PEER }

        if ca_pem.present?
          opts[:cert_store] = OpenSSL::X509::Store.new
          opts[:cert_store].add_cert(OpenSSL::X509::Certificate.new(ca_pem))
        end

        opts
      end

      def cluster_stack
        @cluster_stack ||= provider.api_client.describe_stacks(stack_name: provider.cluster.name).stacks.first
      end

      def stack_output_value(key)
        cluster_stack.outputs.detect { |output| output.output_key == key }.output_value
      end

      def node_instance_role_arn
        stack_output_value('NodeInstanceRole')
      end

      def cluster_endpoint
        strong_memoize(:cluster_endpoint) do
          stack_output_value('ClusterEndpoint')
        end
      end

      def cluster_certificate
        strong_memoize(:cluster_certificate) do
          Base64.decode64(stack_output_value('ClusterCertificate'))
        end
      end

      def configure_node_authentication!
        kube_client.create_config_map(node_authentication_config)
      end

      def node_authentication_config
        Gitlab::Kubernetes::ConfigMaps::AwsNodeAuth.new(node_instance_role_arn).generate
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
