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
        environment_slug = kubernetes_namespace.environment&.slug
        namespace_labels = { 'app.gitlab.com/app' => kubernetes_namespace.project.full_path_slug }
        namespace_labels['app.gitlab.com/env'] = environment_slug if environment_slug

        Clusters::Kubernetes::CreateOrUpdateServiceAccountService.namespace_creator(
          platform.kubeclient,
          service_account_name: kubernetes_namespace.service_account_name,
          service_account_namespace: kubernetes_namespace.namespace,
          service_account_namespace_labels: namespace_labels,
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
