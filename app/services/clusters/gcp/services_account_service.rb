# frozen_string_literal: true

module Clusters
  module Gcp
    class ServicesAccountService
      include ::Gitlab::Utils::StrongMemoize
      attr_reader :kube_client, :cluster

      def initialize(kube_client, cluster)
        @kube_client = kube_client
        @cluster = cluster
      end

      def execute
        create_gitlab_service_account
        create_namespaced_service_account
      end

      private

      def create_gitlab_service_account
        create_service_account(
          name: Clusters::Gcp::Kubernetes::SERVICE_ACCOUNT_NAME,
          namespace: Clusters::Gcp::Kubernetes::SERVICE_ACCOUNT_NAMESPACE
        )
      end

      def create_namespaced_service_account
        create_service_account(
          name: kubernetes_namespace.service_account_name,
          namespace: kubernetes_namespace.namespace
        )
      end

      def create_service_account(name:, namespace:)
        Clusters::Gcp::Kubernetes::CreateServiceAccountService.new(
          kube_client,
          name: name,
          namespace: namespace,
          rbac: cluster.platform_kubernetes_rbac?
        ).execute
      end

      def kubernetes_namespace
        strong_memoize(:kubernetes_namespace) do
          cluster.kubernetes_namespace
        end
      end
    end
  end
end
