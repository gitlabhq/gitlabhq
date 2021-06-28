# frozen_string_literal: true

module Gitlab
  module Recaptcha
    extend Gitlab::Utils::StrongMemoize

    def self.load_configurations!
      if enabled? || enabled_on_login?
        ::Recaptcha.configure do |config|
          config.site_key = Gitlab::CurrentSettings.recaptcha_site_key
          config.secret_key = Gitlab::CurrentSettings.recaptcha_private_key
        end

        true
      end
    end

    def self.enabled?
      Gitlab::CurrentSettings.recaptcha_enabled
    end

    def self.enabled_on_login?
      Gitlab::CurrentSettings.login_recaptcha_protection_enabled
    end
  end
end

# call prepend_mod to ensure JH-specific module run even though there is no corresponding EE-specific module
Gitlab::Recaptcha.prepend_mod
