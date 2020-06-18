# frozen_string_literal: true

module Gitlab
  module Kubernetes
    class NetworkPolicy
      DISABLED_BY_LABEL = :'network-policy.gitlab.com/disabled_by'

      def initialize(name:, namespace:, pod_selector:, ingress:, labels: nil, creation_timestamp: nil, policy_types: ["Ingress"], egress: nil)
        @name = name
        @namespace = namespace
        @labels = labels
        @creation_timestamp = creation_timestamp
        @pod_selector = pod_selector
        @policy_types = policy_types
        @ingress = ingress
        @egress = egress
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
          labels: metadata[:labels],
          pod_selector: spec[:podSelector],
          policy_types: spec[:policyTypes],
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
          labels: metadata[:labels]&.to_h,
          creation_timestamp: metadata[:creationTimestamp],
          pod_selector: spec[:podSelector],
          policy_types: spec[:policyTypes],
          ingress: spec[:ingress],
          egress: spec[:egress]
        )
      end

      def generate
        ::Kubeclient::Resource.new.tap do |resource|
          resource.metadata = metadata
          resource.spec = spec
        end
      end

      def as_json(opts = nil)
        {
          name: name,
          namespace: namespace,
          creation_timestamp: creation_timestamp,
          manifest: manifest,
          is_autodevops: autodevops?,
          is_enabled: enabled?
        }
      end

      def autodevops?
        return false unless labels

        !labels[:chart].nil? && labels[:chart].start_with?('auto-deploy-app-')
      end

      # podSelector selects pods that should be targeted by this
      # policy. We can narrow selection by requiring this policy to
      # match our custom labels. Since DISABLED_BY label will not be
      # on any pod a policy will be effectively disabled.
      def enabled?
        return true unless pod_selector&.key?(:matchLabels)

        !pod_selector[:matchLabels]&.key?(DISABLED_BY_LABEL)
      end

      def enable
        return if enabled?

        pod_selector[:matchLabels].delete(DISABLED_BY_LABEL)
      end

      def disable
        @pod_selector ||= {}
        pod_selector[:matchLabels] ||= {}
        pod_selector[:matchLabels].merge!(DISABLED_BY_LABEL => 'gitlab')
      end

      private

      attr_reader :name, :namespace, :labels, :creation_timestamp, :pod_selector, :policy_types, :ingress, :egress

      def metadata
        meta = { name: name, namespace: namespace }
        meta[:labels] = labels if labels
        meta
      end

      def spec
        {
          podSelector: pod_selector,
          policyTypes: policy_types,
          ingress: ingress,
          egress: egress
        }
      end

      def manifest
        YAML.dump({ metadata: metadata, spec: spec }.deep_stringify_keys)
      end
    end
  end
end
