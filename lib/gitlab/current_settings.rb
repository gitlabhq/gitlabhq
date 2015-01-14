module Gitlab
  module CurrentSettings
    def current_application_settings
      begin
        if ActiveRecord::Base.connection.table_exists?('application_settings')
          ApplicationSetting.current ||
            ApplicationSetting.create_from_defaults
        else
          fake_application_settings
        end
      rescue ActiveRecord::NoDatabaseError, database_adapter.constantize::Error
        fake_application_settings
      end
    end

    def fake_application_settings
      OpenStruct.new(
        default_projects_limit: Settings.gitlab['default_projects_limit'],
        signup_enabled: Settings.gitlab['signup_enabled'],
        signin_enabled: Settings.gitlab['signin_enabled'],
        gravatar_enabled: Settings.gravatar['enabled'],
        sign_in_text: Settings.extra['sign_in_text'],
      )
    end

    # We need to check which database is setup
    # but we cannot assume that the database exists already.
    # Not checking this will break "rake gitlab:setup".
    def database_adapter
      if Rails.configuration.database_configuration[Rails.env]['adapter'] == 'mysql2'
        "Mysql2"
      else
        "PG"
      end
    end
  end
end
