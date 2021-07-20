# frozen_string_literal: true

module Gitlab
  module Kubernetes
    class CiliumNetworkPolicy
      include NetworkPolicyCommon
      extend ::Gitlab::Utils::Override

      API_VERSION = "cilium.io/v2"
      KIND = 'CiliumNetworkPolicy'

      # We are modeling existing kubernetes resource and don't have
      # control over amount of parameters.
      # rubocop:disable Metrics/ParameterLists
      def initialize(name:, namespace:, selector:, ingress:, resource_version: nil, description: nil, labels: nil, creation_timestamp: nil, egress: nil, annotations: nil, environment_ids: [])
        @name = name
        @description = description
        @namespace = namespace
        @labels = labels
        @creation_timestamp = creation_timestamp
        @selector = selector
        @resource_version = resource_version
        @ingress = ingress
        @egress = egress
        @annotations = annotations
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
          description: policy[:description],
          namespace: metadata[:namespace],
          annotations: metadata[:annotations],
          resource_version: metadata[:resourceVersion],
          labels: metadata[:labels],
          selector: spec[:endpointSelector],
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
          description: resource[:description],
          namespace: metadata[:namespace],
          annotations: metadata[:annotations]&.to_h,
          resource_version: metadata[:resourceVersion],
          labels: metadata[:labels]&.to_h,
          creation_timestamp: metadata[:creationTimestamp],
          selector: spec[:endpointSelector],
          ingress: spec[:ingress],
          egress: spec[:egress],
          environment_ids: environment_ids
        )
      end

      override :resource
      def resource
        resource = {
          apiVersion: API_VERSION,
          kind: KIND,
          metadata: metadata,
          spec: spec
        }
        resource[:description] = description if description
        resource
      end

      private

      attr_reader :name, :description, :namespace, :labels, :creation_timestamp, :resource_version, :ingress, :egress, :annotations, :environment_ids

      def selector
        @selector ||= {}
      end

      def metadata
        meta = { name: name, namespace: namespace }
        meta[:labels] = labels if labels
        meta[:resourceVersion] = resource_version if resource_version
        meta[:annotations] = annotations if annotations
        meta
      end

      def spec
        {
          endpointSelector: selector,
          ingress: ingress,
          egress: egress
        }.compact
      end
    end
  end
end
