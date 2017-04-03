module Gitlab
  module CurrentSettings
    def current_application_settings
      if RequestStore.active?
        RequestStore.fetch(:current_application_settings) { ensure_application_settings! }
      else
        ensure_application_settings!
      end
    end

    def ensure_application_settings!
      return fake_application_settings unless connect_to_db?

      unless ENV['IN_MEMORY_APPLICATION_SETTINGS'] == 'true'
        begin
          settings = ::ApplicationSetting.current
        # In case Redis isn't running or the Redis UNIX socket file is not available
        rescue ::Redis::BaseError, ::Errno::ENOENT
          settings = ::ApplicationSetting.last
        end

        settings ||= ::ApplicationSetting.create_from_defaults unless ActiveRecord::Migrator.needs_migration?
      end

      settings || in_memory_application_settings
    end

    delegate :sidekiq_throttling_enabled?, to: :current_application_settings

    def in_memory_application_settings
      @in_memory_application_settings ||= ::ApplicationSetting.new(::ApplicationSetting.defaults)
    # In case migrations the application_settings table is not created yet,
    # we fallback to a simple OpenStruct
    rescue ActiveRecord::StatementInvalid, ActiveRecord::UnknownAttributeError
      fake_application_settings
    end

    def fake_application_settings
      OpenStruct.new(::ApplicationSetting.defaults)
    end

    private

    def connect_to_db?
      # When the DBMS is not available, an exception (e.g. PG::ConnectionBad) is raised
      active_db_connection = ActiveRecord::Base.connection.active? rescue false

      active_db_connection &&
        ActiveRecord::Base.connection.table_exists?('application_settings')
    rescue ActiveRecord::NoDatabaseError
      false
    end
  end
end
