module Ci
  module CurrentSettings
    def current_application_settings
      key = :ci_current_application_settings

      RequestStore.store[key] ||= begin
        if ActiveRecord::Base.connected? && ActiveRecord::Base.connection.table_exists?('ci_application_settings')
          Ci::ApplicationSetting.current || Ci::ApplicationSetting.create_from_defaults
        else
          fake_application_settings
        end
      end
    end

    def fake_application_settings
      OpenStruct.new(
        all_broken_builds: Ci::Settings.gitlab_ci['all_broken_builds'],
        add_pusher: Ci::Settings.gitlab_ci['add_pusher'],
      )
    end
  end
end
