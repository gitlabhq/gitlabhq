module Gitlab
  class PollingInterval
    include Gitlab::CurrentSettings

    HEADER_NAME = 'Poll-Interval'.freeze

    def self.set_header(response, interval:)
      if polling_enabled?
        multiplier = current_application_settings.polling_interval_multiplier
        value = (interval * multiplier).to_i
      else
        value = -1
      end

      response.headers[HEADER_NAME] = value.to_s
    end

    def self.polling_enabled?
      !current_application_settings.polling_interval_multiplier.zero?
    end
  end
end
