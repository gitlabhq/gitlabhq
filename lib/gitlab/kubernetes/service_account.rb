# frozen_string_literal: true

module Gitlab
  module Kubernetes
    class ServiceAccount
      attr_reader :name, :namespace_name

      def initialize(name, namespace_name)
        @name = name
        @namespace_name = namespace_name
      end

      def generate
        ::Kubeclient::Resource.new(metadata: metadata)
      end

      private

      def metadata
        {
          name: name,
          namespace: namespace_name
        }
      end
    end
  end
end
