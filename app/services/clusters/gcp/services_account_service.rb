# frozen_string_literal: true

module Clusters
  module Gcp
    class ServicesAccountService
      attr_reader :kube_client, :cluster

      def initialize(kube_client, cluster)
        @kube_client = kube_client
        @cluster = cluster
      end

      def execute
        create_service_account
        create_namespaced_service_account
      end

      private

      def create_namespaced_service_account
        return unless cluster.platform_kubernetes_rbac?

        namespace_name = cluster.platform_kubernetes.actual_namespace

        ensure_namespace_exists(namespace_name)
        create_service_account(namespace: namespace_name, rbac: true)
      end

      def ensure_namespace_exists(namespace_name)
        Gitlab::Kubernetes::Namespace.new(namespace_name, kube_client).ensure_exists!
      end

      def create_service_account(namespace: 'default', rbac: false)
        Clusters::Gcp::Kubernetes::CreateServiceAccountService.new(
          kube_client,
          name: cluster.platform_kubernetes.service_account_name,
          namespace: namespace,
          rbac: rbac
        ).execute
      end
    end
  end
end
