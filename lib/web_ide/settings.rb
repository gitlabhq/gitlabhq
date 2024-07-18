# frozen_string_literal: true

module WebIde
  module Settings
    extend Gitlab::Fp::Settings::PublicApi

    def self.settings_main_class
      WebIde::Settings::Main
    end
  end
end
