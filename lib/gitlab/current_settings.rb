module Gitlab
  module CurrentSettings
    def current_application_settings
      if RequestStore.active?
        RequestStore.fetch(:current_application_settings) { ensure_application_settings! }
      else
        ensure_application_settings!
      end
    end

    delegate :sidekiq_throttling_enabled?, to: :current_application_settings

    def fake_application_settings
      OpenStruct.new(::ApplicationSetting.defaults)
    end

    private

    def ensure_application_settings!
      unless ENV['IN_MEMORY_APPLICATION_SETTINGS'] == 'true'
        settings = retrieve_settings_from_database?
      end

      settings || in_memory_application_settings
    end

    def retrieve_settings_from_database?
      settings = retrieve_settings_from_database_cache?
      return settings if settings.present?

      return fake_application_settings unless connect_to_db?

      begin
        db_settings = ::ApplicationSetting.current
        # In case Redis isn't running or the Redis UNIX socket file is not available
      rescue ::Redis::BaseError, ::Errno::ENOENT
        db_settings = ::ApplicationSetting.last
      end
      db_settings || ::ApplicationSetting.create_from_defaults
    end

    def retrieve_settings_from_database_cache?
      begin
        settings = ApplicationSetting.cached
      rescue ::Redis::BaseError, ::Errno::ENOENT
        # In case Redis isn't running or the Redis UNIX socket file is not available
        settings = nil
      end
      settings
    end

    def in_memory_application_settings
      @in_memory_application_settings ||= ::ApplicationSetting.new(::ApplicationSetting.defaults)
    rescue ActiveRecord::StatementInvalid, ActiveRecord::UnknownAttributeError
      # In case migrations the application_settings table is not created yet,
      # we fallback to a simple OpenStruct
      fake_application_settings
    end

    def connect_to_db?
      # When the DBMS is not available, an exception (e.g. PG::ConnectionBad) is raised
      active_db_connection = ActiveRecord::Base.connection.active? rescue false

      active_db_connection &&
        ActiveRecord::Base.connection.table_exists?('application_settings') &&
        !ActiveRecord::Migrator.needs_migration?
    rescue ActiveRecord::NoDatabaseError
      false
    end
  end
end
