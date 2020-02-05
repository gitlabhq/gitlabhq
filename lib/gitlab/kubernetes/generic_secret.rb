# frozen_string_literal: true

module Gitlab
  module Kubernetes
    class GenericSecret
      attr_reader :name, :data, :namespace_name

      def initialize(name, data, namespace_name)
        @name = name
        @data = data
        @namespace_name = namespace_name
      end

      def generate
        ::Kubeclient::Resource.new(
          type: generic_secret_type,
          metadata: metadata,
          data: data
        )
      end

      private

      def generic_secret_type
        'Opaque'
      end

      def metadata
        {
          name: name,
          namespace: namespace_name
        }
      end
    end
  end
end
