# frozen_string_literal: true

module Clusters
  module Kubernetes
    class CreateOrUpdateNamespaceService
      def initialize(cluster:, kubernetes_namespace:)
        @cluster = cluster
        @kubernetes_namespace = kubernetes_namespace
        @platform = cluster.platform
      end

      def execute
        create_project_service_account
        configure_kubernetes_token

        kubernetes_namespace.save!
      end

      private

      attr_reader :cluster, :kubernetes_namespace, :platform

      def create_project_service_account
        Clusters::Kubernetes::CreateOrUpdateServiceAccountService.namespace_creator(
          platform.kubeclient,
          service_account_name: kubernetes_namespace.service_account_name,
          service_account_namespace: kubernetes_namespace.namespace,
          rbac: platform.rbac?
        ).execute
      end

      def configure_kubernetes_token
        kubernetes_namespace.service_account_token = fetch_service_account_token
      end

      def fetch_service_account_token
        Clusters::Kubernetes::FetchKubernetesTokenService.new(
          platform.kubeclient,
          kubernetes_namespace.token_name,
          kubernetes_namespace.namespace
        ).execute
      end
    end
  end
end
