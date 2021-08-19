# frozen_string_literal: true

module Gitlab
  module CurrentSettings
    class << self
      def signup_disabled?
        !signup_enabled?
      end

      def signup_limited?
        domain_allowlist.present? || email_restrictions_enabled? || require_admin_approval_after_user_signup?
      end

      def current_application_settings
        Gitlab::SafeRequestStore.fetch(:current_application_settings) { ensure_application_settings! }
      end

      def current_application_settings?
        Gitlab::SafeRequestStore.exist?(:current_application_settings) || ::ApplicationSetting.current.present?
      end

      def expire_current_application_settings
        ::ApplicationSetting.expire
        Gitlab::SafeRequestStore.delete(:current_application_settings)
      end

      def clear_in_memory_application_settings!
        @in_memory_application_settings = nil
      end

      def method_missing(name, *args, **kwargs, &block)
        current_application_settings.send(name, *args, **kwargs, &block) # rubocop:disable GitlabSecurity/PublicSend
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
        rescue StandardError
          # In case Redis isn't running
          # or the Redis UNIX socket file is not available
          # or the DB is not running (we use migrations in the cache key)
        end
      end

      def uncached_application_settings
        return fake_application_settings if Gitlab::Runtime.rake? && !connect_to_db?

        current_settings = ::ApplicationSetting.current
        # If there are pending migrations, it's possible there are columns that
        # need to be added to the application settings. To prevent Rake tasks
        # and other callers from failing, use any loaded settings and return
        # defaults for missing columns.
        if Gitlab::Runtime.rake? && ActiveRecord::Base.connection.migration_context.needs_migration?
          db_attributes = current_settings&.attributes || {}
          fake_application_settings(db_attributes)
        elsif current_settings.present?
          current_settings
        else
          ::ApplicationSetting.create_from_defaults
        end
      end

      def fake_application_settings(attributes = {})
        Gitlab::FakeApplicationSettings.new(::ApplicationSetting.defaults.merge(attributes || {}))
      end

      def in_memory_application_settings
        @in_memory_application_settings ||= ::ApplicationSetting.build_from_defaults
      end

      def connect_to_db?
        # When the DBMS is not available, an exception (e.g. PG::ConnectionBad) is raised
        active_db_connection = ActiveRecord::Base.connection.active? rescue false

        active_db_connection &&
          Gitlab::Database.main.cached_table_exists?('application_settings')
      rescue ActiveRecord::NoDatabaseError
        false
      end
    end
  end
end
