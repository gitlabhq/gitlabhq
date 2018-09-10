module Gitlab
  module CurrentSettings
    class << self
      def current_application_settings
        if RequestStore.active?
          RequestStore.fetch(:current_application_settings) { ensure_application_settings! }
        else
          ensure_application_settings!
        end
      end

      def fake_application_settings(attributes = {})
        Gitlab::FakeApplicationSettings.new(::ApplicationSetting.defaults.merge(attributes || {}))
      end

      def clear_in_memory_application_settings!
        instance_variable_set(:@in_memory_application_settings, nil)
      end

      def method_missing(name, *args, &block)
        current_application_settings.send(name, *args, &block) # rubocop:disable GitlabSecurity/PublicSend
      end

      def respond_to_missing?(name, include_private = false)
        current_application_settings.respond_to?(name, include_private) || super
      end

      private

      def ensure_application_settings!
        cached_application_settings || uncached_application_settings
      end

      def cached_application_settings
        return in_memory_application_settings if ENV['IN_MEMORY_APPLICATION_SETTINGS'] == 'true'

        begin
          ::ApplicationSetting.cached
        rescue
          # In case Redis isn't running
          # or the Redis UNIX socket file is not available
          # or the DB is not running (we use migrations in the cache key)
        end
      end

      def uncached_application_settings
        return fake_application_settings unless connect_to_db?

        current_settings = ::ApplicationSetting.current
        # If there are pending migrations, it's possible there are columns that
        # need to be added to the application settings. To prevent Rake tasks
        # and other callers from failing, use any loaded settings and return
        # defaults for missing columns.
        if ActiveRecord::Migrator.needs_migration?
          return fake_application_settings(current_settings&.attributes)
        end

        return current_settings if current_settings.present?

        with_fallback_to_fake_application_settings do
          ::ApplicationSetting.create_from_defaults || in_memory_application_settings
        end
      end

      def in_memory_application_settings
        with_fallback_to_fake_application_settings do
          @in_memory_application_settings ||= ::ApplicationSetting.build_from_defaults
        end
      end

      def with_fallback_to_fake_application_settings(&block)
        yield
      rescue
        # In case the application_settings table is not created yet, or if a new
        # ApplicationSetting column is not yet migrated we fallback to a simple OpenStruct
        fake_application_settings
      end

      def connect_to_db?
        # When the DBMS is not available, an exception (e.g. PG::ConnectionBad) is raised
        active_db_connection = ActiveRecord::Base.connection.active? rescue false

        active_db_connection &&
          Gitlab::Database.cached_table_exists?('application_settings')
      rescue ActiveRecord::NoDatabaseError
        false
      end
    end
  end
end
