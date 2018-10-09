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

        cluster_kubernetes_namespace.ensure_exists!

        # To do: Create service account
      end

      private

      def cluster_kubernetes_namespace
        strong_memoize(:cluster_kubernetes_namespace) do
          Gitlab::Kubernetes::Namespace.new(namespace_name, platform.kubeclient)
        end
      end

      def namespace_name
        platform.cluster_project.kubernetes_namespace.namespace
      end
    end
  end
end
