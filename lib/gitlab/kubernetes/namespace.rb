module Gitlab
  module Kubernetes
    class Namespace
      attr_accessor :name

      def initialize(name, client)
        @name = name
        @client = client
      end

      def exists?
        @client.get_namespace(name)
      rescue ::Kubeclient::ResourceNotFoundError
        false
      end

      def create!
        resource = ::Kubeclient::Resource.new(metadata: { name: name })

        @client.create_namespace(resource)
      end

      def ensure_exists!
        exists? || create!
      end
    end
  end
end
