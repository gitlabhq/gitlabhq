# frozen_string_literal: true

module Gitlab
  module ApplicationSettingFetcher
    class << self
      def clear_in_memory_application_settings!
        @in_memory_application_settings = nil
      end

      def current_application_settings
        cached_application_settings || uncached_application_settings
      end

      def current_application_settings?
        ::ApplicationSetting.current.present?
      end

      def expire_current_application_settings
        ::ApplicationSetting.expire
      end

      private

      def cached_application_settings
        return in_memory_application_settings if ENV['IN_MEMORY_APPLICATION_SETTINGS'] == 'true'

        ::ApplicationSetting.cached
      end

      def uncached_application_settings
        return fake_application_settings if Gitlab::Runtime.rake? && !connect_to_db?

        current_settings = ::ApplicationSetting.current

        # If there are pending migrations, it's possible there are columns that
        # need to be added to the application settings. To prevent Rake tasks
        # and other callers from failing, use any loaded settings and return
        # defaults for missing columns.
        if Gitlab::Runtime.rake? && ::ApplicationSetting.connection.migration_context.needs_migration?
          db_attributes = current_settings&.attributes || {}
          fake_application_settings(db_attributes)
        elsif current_settings.present?
          current_settings
        else
          ::ApplicationSetting.create_from_defaults
        end
      rescue ::ApplicationSetting::Recursion
        in_memory_application_settings
      end

      def in_memory_application_settings
        @in_memory_application_settings ||= ::ApplicationSetting.build_from_defaults
      end

      def fake_application_settings(attributes = {})
        Gitlab::FakeApplicationSettings.new(::ApplicationSetting.defaults.merge(attributes || {}))
      end

      def connect_to_db?
        # When the DBMS is not available, an exception (e.g. PG::ConnectionBad) is raised
        active_db_connection = begin
          ::ApplicationSetting.connection.active?
        rescue StandardError
          false
        end

        active_db_connection &&
          ApplicationSetting.database.cached_table_exists?
      rescue ActiveRecord::NoDatabaseError
        false
      end
    end
  end
end
