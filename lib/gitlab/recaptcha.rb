module Gitlab
  module Recaptcha
    def self.load_configurations!
      if Gitlab::CurrentSettings.recaptcha_enabled
        ::Recaptcha.configure do |config|
          config.public_key  = Gitlab::CurrentSettings.recaptcha_site_key
          config.private_key = Gitlab::CurrentSettings.recaptcha_private_key
        end

        true
      end
    end

    def self.enabled?
      Gitlab::CurrentSettings.recaptcha_enabled
    end
  end
end
