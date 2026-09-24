# frozen_string_literal: true

module Gitlab
  module Mfe
    # Holds the runtime hooks the host application injects. Each hook has a
    # safe default so the gem and its own specs run without a host: delivery
    # is off and no custom registry. The gem does not know feature flags
    # exist; the host resolves the config-and-flag AND into the single
    # `enabled` hook.
    class Configuration
      attr_writer :enabled, :registry_url, :vendor_file_path

      def enabled?
        resolve(@enabled, false)
      end

      def registry_url
        resolve(@registry_url, nil)
      end

      def vendor_file_path
        resolve(@vendor_file_path, nil)
      end

      private

      def resolve(value, default)
        return default if value.nil?

        value.respond_to?(:call) ? value.call : value
      end
    end
  end
end
