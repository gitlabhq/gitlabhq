# frozen_string_literal: true

module Clusters
  module Kubernetes
    class ConfigureService
      include Gitlab::Utils::StrongMemoize

      attr_reader :platform

      def initialize(platform)
        @platform = platform
      end

      def execute
        return unless platform.cluster_project

        kubernetes_namespace.ensure_exists!

        platform.cluster_project.update!(
          namespace: kubernetes_namespace.name,
          service_account_name: service_account_name
        )
      end

      private

      def kubernetes_namespace
        strong_memoize(:kubernetes_namespace) do
          Gitlab::Kubernetes::Namespace.new(namespace_name, platform.kubeclient)
        end
      end

      def namespace_name
        platform.namespace.presence || platform.cluster_project.default_namespace
      end

      def service_account_name
        if platform.rbac?
          "#{default_service_account_name}-#{namespace_name}"
        else
          default_service_account_name
        end
      end

      def default_service_account_name
        Clusters::Gcp::Kubernetes::SERVICE_ACCOUNT_NAME
      end
    end
  end
end
