# frozen_string_literal: true

module Gitlab
  module ProtocolAccess
    class << self
      def allowed?(protocol, project: nil)
        # Web is always allowed
        return true if protocol == "web"

        # System settings
        return false unless instance_allowed?(protocol)

        # Group-level settings
        return false unless namespace_allowed?(protocol, namespace: project&.root_namespace)

        # Default to allowing all protocols
        true
      end

      private

      def instance_allowed?(protocol)
        # If admin hasn't configured this setting, default to true
        return true if Gitlab::CurrentSettings.enabled_git_access_protocol.blank?

        protocol == Gitlab::CurrentSettings.enabled_git_access_protocol
      end

      def namespace_allowed?(protocol, namespace: nil)
        # If the namespace parameter was nil, we default to true here
        return true if namespace.nil?

        # Return immediately if all protocols are allowed
        return true if namespace.enabled_git_access_protocol == "all"

        # If the setting is somehow nil, such as in an unsaved state, we default to allow
        return true if namespace.enabled_git_access_protocol.blank?

        protocol == namespace.enabled_git_access_protocol
      end
    end
  end
end
