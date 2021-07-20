# frozen_string_literal: true

module Gitlab
  module Kubernetes
    class NetworkPolicy
      include NetworkPolicyCommon
      extend ::Gitlab::Utils::Override

      KIND = 'NetworkPolicy'

      # rubocop:disable Metrics/ParameterLists
      def initialize(name:, namespace:, selector:, ingress:, labels: nil, creation_timestamp: nil, policy_types: ["Ingress"], egress: nil, environment_ids: [])
        @name = name
        @namespace = namespace
        @labels = labels
        @creation_timestamp = creation_timestamp
        @selector = selector
        @policy_types = policy_types
        @ingress = ingress
        @egress = egress
        @environment_ids = environment_ids
      end
      # rubocop:enable Metrics/ParameterLists

      def self.from_yaml(manifest)
        return unless manifest

        policy = YAML.safe_load(manifest, symbolize_names: true)
        return if !policy[:metadata] || !policy[:spec]

        metadata = policy[:metadata]
        spec = policy[:spec]
        self.new(
          name: metadata[:name],
          namespace: metadata[:namespace],
          labels: metadata[:labels],
          selector: spec[:podSelector],
          policy_types: spec[:policyTypes],
          ingress: spec[:ingress],
          egress: spec[:egress]
        )
      rescue Psych::SyntaxError, Psych::DisallowedClass
        nil
      end

      def self.from_resource(resource, environment_ids = [])
        return unless resource
        return if !resource[:metadata] || !resource[:spec]

        metadata = resource[:metadata]
        spec = resource[:spec].to_h
        self.new(
          name: metadata[:name],
          namespace: metadata[:namespace],
          labels: metadata[:labels]&.to_h,
          creation_timestamp: metadata[:creationTimestamp],
          selector: spec[:podSelector],
          policy_types: spec[:policyTypes],
          ingress: spec[:ingress],
          egress: spec[:egress],
          environment_ids: environment_ids
        )
      end

      override :resource
      def resource
        {
          kind: KIND,
          metadata: metadata,
          spec: spec
        }
      end

      private

      attr_reader :name, :namespace, :labels, :creation_timestamp, :policy_types, :ingress, :egress, :environment_ids

      def selector
        @selector ||= {}
      end

      def metadata
        meta = { name: name, namespace: namespace }
        meta[:labels] = labels if labels
        meta
      end

      def spec
        {
          podSelector: selector,
          policyTypes: policy_types,
          ingress: ingress,
          egress: egress
        }
      end
    end
  end
end
