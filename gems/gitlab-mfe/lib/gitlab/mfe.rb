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
      def configure
        yield configuration if block_given?
        VendorFile.reset!
        configuration
      end

      def configuration
        @configuration ||= Configuration.new
      end

      def reset_configuration!
        @configuration = nil
        VendorFile.reset!
      end

      def enabled?
        configuration.enabled?
      end

      def registry_url
        configuration.registry_url || DEFAULT_REGISTRY_URL
      end
    end
  end
end
