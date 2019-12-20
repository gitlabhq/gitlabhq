# frozen_string_literal: true

module Gitlab
  module Kubernetes
    class ClusterRole
      attr_reader :name, :rules

      def initialize(name:, rules:)
        @name = name
        @rules = rules
      end

      def generate
        ::Kubeclient::Resource.new(
          metadata: metadata,
          rules: rules
        )
      end

      private

      def metadata
        {
          name: name
        }
      end
    end
  end
end
