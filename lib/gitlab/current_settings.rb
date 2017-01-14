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
      if connect_to_db?
        begin
          settings = ::ApplicationSetting.current
        # In case Redis isn't running or the Redis UNIX socket file is not available
        rescue ::Redis::BaseError, ::Errno::ENOENT
          settings = ::ApplicationSetting.last
        end

        settings ||= ::ApplicationSetting.create_from_defaults unless ActiveRecord::Migrator.needs_migration?
      end

      settings || fake_application_settings
    end

    def sidekiq_throttling_enabled?
      current_application_settings.sidekiq_throttling_enabled?
    end

    def fake_application_settings
      ApplicationSetting.new(ApplicationSetting::DEFAULTS)
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
