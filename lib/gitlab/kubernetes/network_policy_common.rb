# frozen_string_literal: true

module Gitlab
  module Kubernetes
    module NetworkPolicyCommon
      DISABLED_BY_LABEL = :'network-policy.gitlab.com/disabled_by'

      def generate
        ::Kubeclient::Resource.new(resource)
      end

      def as_json(opts = nil)
        {
          name: name,
          namespace: namespace,
          creation_timestamp: creation_timestamp,
          manifest: manifest,
          is_autodevops: autodevops?,
          is_enabled: enabled?,
          environment_ids: environment_ids
        }
      end

      def autodevops?
        return false unless labels

        !labels[:chart].nil? && labels[:chart].start_with?('auto-deploy-app-')
      end

      # selector selects pods that should be targeted by this
      # policy. It can represent podSelector, nodeSelector or
      # endpointSelector  We can narrow selection by requiring
      # this policy to match our custom labels. Since DISABLED_BY
      # label will not be on any pod a policy will be effectively disabled.
      def enabled?
        return true unless selector&.key?(:matchLabels)

        !selector[:matchLabels]&.key?(DISABLED_BY_LABEL)
      end

      def enable
        return if enabled?

        selector[:matchLabels].delete(DISABLED_BY_LABEL)
      end

      def disable
        selector[:matchLabels] ||= {}
        selector[:matchLabels].merge!(DISABLED_BY_LABEL => 'gitlab')
      end

      private

      def resource
        raise NotImplementedError
      end

      def manifest
        YAML.dump(resource.deep_stringify_keys)
      end
    end
  end
end
