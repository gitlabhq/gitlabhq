module Gitlab
  module Kubernetes
    class ConfigMap
      def initialize(name, config_files)
        @name = name
        @config_files = config_files
      end

      def generate
        resource = ::Kubeclient::Resource.new
        resource.metadata = metadata
        resource.data = config_files
        resource
      end

      private

      attr_reader :name, :config_files

      def metadata
        {
          name: config_map_name,
          namespace: namespace,
          labels: { name: config_map_name }
        }
      end

      def config_map_name
        "values-content-configuration-#{name}"
      end

      def namespace
        Gitlab::Kubernetes::Helm::NAMESPACE
      end
    end
  end
end
