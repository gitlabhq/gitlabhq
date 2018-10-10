# frozen_string_literal: true

module Clusters
  module Kubernetes
    class ConfigureService
      include Gitlab::Utils::StrongMemoize

      attr_reader :platform, :cluster

      def initialize(cluster)
        @cluster = cluster
        @platform = cluster.platform
      end

      def execute
        return unless cluster_project

        create_kubernetes_namespace!
        create_services_accounts!
        configure_kubernetes_token
      end

      private

      def create_kubernetes_namespace!
        cluster_project.kubernetes_namespaces.create!
      end

      def create_services_accounts!
        Clusters::Gcp::ServicesAccountService.new(platform.kubeclient, cluster).execute
      end

      def configure_kubernetes_token
        service_token_account = fetch_kubernetes_token(kubernetes_namespace.token_name, kubernetes_namespace.namespace)

        kubernetes_namespace.update_attribute(:service_account_token, service_token_account)
      end

      def fetch_kubernetes_token(name, namespace)
        Clusters::Gcp::Kubernetes::FetchKubernetesTokenService.new(platform.kubeclient, name, namespace).execute
      end

      def kubernetes_namespace
        strong_memoize(:kubernetes_namespace) do
          cluster.kubernetes_namespace
        end
      end

      def cluster_project
        strong_memoize(:cluster_project) do
          cluster.cluster_project
        end
      end
    end
  end
end
