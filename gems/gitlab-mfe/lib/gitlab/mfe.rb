# frozen_string_literal: true

require "yaml"
require "active_support/core_ext/object/blank"
require "active_support/core_ext/hash/keys"
require "gitlab/utils/strong_memoize"

require_relative "mfe/version"
require_relative "mfe/configuration"
require_relative "mfe/vendor_file"

module Gitlab
  module Mfe
    DEFAULT_REGISTRY_URL = 'https://mfe.gitlab.com'

    class << self
      # The host application (the GitLab monolith) wires the runtime
      # dependencies this gem cannot reach on its own: whether delivery is
      # enabled, the custom registry URL, and the path of the committed pin
      # file. See ADR-004 for why a library gem stays free of `Feature`,
      # `Gitlab.config` and `Rails`.
      def configure
        yield configuration if block_given?
        configuration
      end

      def configuration
        @configuration ||= Configuration.new
      end

      def reset_configuration!
        @configuration = nil
      end

      # Whether micro-frontend delivery is active for this instance.
      #
      # The host resolves the static `gitlab.yml` `mfe.enabled` switch and the
      # `mfe_enabled` feature flag into the injected `enabled` hook, so the gem
      # itself stays free of feature-flag knowledge.
      def enabled?
        configuration.enabled?
      end

      def registry_url
        configuration.registry_url || DEFAULT_REGISTRY_URL
      end
    end
  end
end
