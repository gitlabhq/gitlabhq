# frozen_string_literal: true

module Clusters
  module Kubernetes
    class ConfigureService
      attr_reader :platform

      def initialize(platform)
        @platform = platform
      end

      def execute
        return unless platform.cluster_project

        namespace.ensure_exists!

        platform.cluster_project.update!(namespace: namespace.name)
      end

      private

      def namespace
        Gitlab::Kubernetes::Namespace.new(platform.actual_namespace, platform.kubeclient)
      end
    end
  end
end
