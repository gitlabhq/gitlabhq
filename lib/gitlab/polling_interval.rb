# frozen_string_literal: true

module Gitlab
  class PollingInterval
    HEADER_NAME = 'Poll-Interval'

    def self.set_header(response, interval:)
      response.headers[HEADER_NAME] = polling_interval_value(interval).to_s
    end

    def self.set_api_header(context, interval:)
      context.header HEADER_NAME, polling_interval_value(interval).to_s
    end

    def self.polling_interval_value(interval)
      return -1 unless polling_enabled?

      multiplier = Gitlab::CurrentSettings.polling_interval_multiplier
      (interval * multiplier).to_i
    end

    def self.polling_enabled?
      Gitlab::CurrentSettings.polling_interval_multiplier != 0
    end
  end
end
