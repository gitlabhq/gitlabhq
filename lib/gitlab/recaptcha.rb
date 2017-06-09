module Gitlab
  module Recaptcha
    def self.load_configurations!
      if self.current_settings.recaptcha_enabled
        ::Recaptcha.configure do |config|
          config.public_key  = self.current_settings.recaptcha_site_key
          config.private_key = self.current_settings.recaptcha_private_key
        end

        true
      end
    end

    def self.enabled?
      self.current_settings.recaptcha_enabled
    end

    def self.current_settings
      Class.new.extend(CurrentSettings).current_application_settings
    end
  end
end
