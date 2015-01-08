module Gitlab
  module CurrentSettings
    def current_application_settings
      ApplicationSetting.current
    end
  end
end
