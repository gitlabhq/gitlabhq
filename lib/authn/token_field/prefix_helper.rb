# frozen_string_literal: true

module Authn
  module TokenField
    class PrefixHelper
      def self.prepend_instance_prefix(prefix)
        "#{instance_prefix}#{prefix}"
      end

      def self.instance_prefix
        # This is an admin setting, so we should go with :instance
        # https://docs.gitlab.com/ee/development/feature_flags/#instance-actor
        return '' unless Feature.enabled?(:custom_prefix_for_all_token_types, :instance)

        Gitlab::CurrentSettings.current_application_settings.instance_token_prefix
      end

      def self.default_instance_prefix(prefix)
        return prefix unless Feature.enabled?(:custom_prefix_for_all_token_types, :instance)

        return prefix unless prefix.starts_with?(instance_prefix)

        # remove the configured instance prefix and add the default:
        "#{ApplicationSetting.defaults[:instance_token_prefix]}#{prefix.delete_prefix(instance_prefix)}"
      end
    end
  end
end
