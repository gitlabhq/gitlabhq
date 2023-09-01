# frozen_string_literal: true

module Gitlab
  module SilentMode
    def self.enabled?
      Gitlab::CurrentSettings.silent_mode_enabled?
    end

    def self.enable!
      Gitlab::CurrentSettings.update!(silent_mode_enabled: true)
    end

    def self.log_info(data)
      Gitlab::AppJsonLogger.info(**add_silent_mode_log_data(data))
    end

    def self.log_debug(data)
      Gitlab::AppJsonLogger.debug(**add_silent_mode_log_data(data))
    end

    def self.add_silent_mode_log_data(data)
      data.merge!({ silent_mode_enabled: enabled? })
    end
  end
end
