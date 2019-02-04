# frozen_string_literal: true

module Gitlab
  module Kubernetes
    class ConfigMap
      def initialize(name, files)
        @name = name
        @files = files
      end

      def generate
        resource = ::Kubeclient::Resource.new
        resource.metadata = metadata
        resource.data = files
        resource
      end

      def config_map_name
        "values-content-configuration-#{name}"
      end

      private

      attr_reader :name, :files

      def metadata
        {
          name: config_map_name,
          namespace: namespace,
          labels: { name: config_map_name }
        }
      end

      def namespace
        Gitlab::Kubernetes::Helm::NAMESPACE
      end
    end
  end
end
