# frozen_string_literal: true

module Authn
  module TokenField
    class PrefixHelper
      # 'gl' was the instance_token_prefix default until 2025-05-11 and is still
      # persisted on instances that saved settings then. Treat it as unset so we
      # never prepend "gl-", even before ResetLegacyInstanceTokenPrefix runs.
      LEGACY_DEFAULT_PREFIX = 'gl'

      def self.prepend_instance_prefix(prefix)
        configured_prefix = instance_prefix
        return prefix if configured_prefix.blank?

        "#{configured_prefix}-#{prefix}"
      end

      def self.instance_prefix
        # This is an admin setting, so we should go with :instance
        # https://docs.gitlab.com/ee/development/feature_flags/#instance-actor
        return '' unless Feature.enabled?(:custom_prefix_for_all_token_types, :instance)

        prefix = Gitlab::CurrentSettings.current_application_settings.instance_token_prefix
        return '' if prefix == LEGACY_DEFAULT_PREFIX

        prefix
      end
    end
  end
end
