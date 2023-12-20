# frozen_string_literal: true

module Gitlab
  module ApplicationSettingFetcher
    class << self
      def clear_in_memory_application_settings!
        @in_memory_application_settings = nil
      end

      def current_application_settings
        cached_application_settings
      end

      private

      def cached_application_settings
        return in_memory_application_settings if ENV['IN_MEMORY_APPLICATION_SETTINGS'] == 'true'

        begin
          ::ApplicationSetting.cached
        rescue StandardError
          # In case Redis isn't running
          # or the Redis UNIX socket file is not available
          # or the DB is not running (we use migrations in the cache key)
        end
      end

      def in_memory_application_settings
        @in_memory_application_settings ||= ::ApplicationSetting.build_from_defaults
      end
    end
  end
end
