# frozen_string_literal: true

module Gitlab
  module Kubernetes
    class CiliumNetworkPolicy
      include NetworkPolicyCommon
      extend ::Gitlab::Utils::Override

      API_VERSION = "cilium.io/v2"
      KIND = 'CiliumNetworkPolicy'

      def initialize(name:, namespace:, selector:, ingress:, resource_version:, labels: nil, creation_timestamp: nil, egress: nil)
        @name = name
        @namespace = namespace
        @labels = labels
        @creation_timestamp = creation_timestamp
        @selector = selector
        @resource_version = resource_version
        @ingress = ingress
        @egress = egress
      end

      def generate
        ::Kubeclient::Resource.new.tap do |resource|
          resource.kind = KIND
          resource.apiVersion = API_VERSION
          resource.metadata = metadata
          resource.spec = spec
        end
      end

      def self.from_yaml(manifest)
        return unless manifest

        policy = YAML.safe_load(manifest, symbolize_names: true)
        return if !policy[:metadata] || !policy[:spec]

        metadata = policy[:metadata]
        spec = policy[:spec]
        self.new(
          name: metadata[:name],
          namespace: metadata[:namespace],
          resource_version: metadata[:resourceVersion],
          labels: metadata[:labels],
          selector: spec[:endpointSelector],
          ingress: spec[:ingress],
          egress: spec[:egress]
        )
      rescue Psych::SyntaxError, Psych::DisallowedClass
        nil
      end

      def self.from_resource(resource)
        return unless resource
        return if !resource[:metadata] || !resource[:spec]

        metadata = resource[:metadata]
        spec = resource[:spec].to_h
        self.new(
          name: metadata[:name],
          namespace: metadata[:namespace],
          resource_version: metadata[:resourceVersion],
          labels: metadata[:labels]&.to_h,
          creation_timestamp: metadata[:creationTimestamp],
          selector: spec[:endpointSelector],
          ingress: spec[:ingress],
          egress: spec[:egress]
        )
      end

      private

      attr_reader :name, :namespace, :labels, :creation_timestamp, :resource_version, :ingress, :egress

      def selector
        @selector ||= {}
      end

      override :spec
      def spec
        {
          endpointSelector: selector,
          ingress: ingress,
          egress: egress
        }
      end
    end
  end
end
