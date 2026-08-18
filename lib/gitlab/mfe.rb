# frozen_string_literal: true

module Gitlab
  module Mfe
    DEFAULT_REGISTRY_URL = 'https://mfe.gitlab.com'

    class << self
      # Whether micro-frontend delivery is active for this instance.
      #
      # Requires both the static `gitlab.yml` `mfe.enabled` switch and the
      # `mfe_enabled` feature flag, so operators keep a static kill switch
      # while rollout stays flag-gated.
      def enabled?
        config_enabled? && Feature.enabled?(:mfe_enabled, :instance)
      end

      def registry_url
        Gitlab.config.mfe.registry_url
      rescue ::Gitlab::Configs::MissingConfig
        # The `mfe` section is optional; fall back to the default registry.
        DEFAULT_REGISTRY_URL
      end

      private

      def config_enabled?
        Gitlab.config.mfe.enabled
      rescue ::Gitlab::Configs::MissingConfig
        # The `mfe` section is optional; a missing section means delivery is off.
        false
      end
    end
  end
end
