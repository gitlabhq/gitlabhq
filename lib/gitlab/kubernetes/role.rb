# frozen_string_literal: true

module Gitlab
  module Kubernetes
    class Role
      def initialize(name:, namespace:, rules:)
        @name = name
        @namespace = namespace
        @rules = rules
      end

      def generate
        ::Kubeclient::Resource.new(
          metadata: { name: name, namespace: namespace },
          rules: rules
        )
      end

      private

      attr_reader :name, :namespace, :rules
    end
  end
end
