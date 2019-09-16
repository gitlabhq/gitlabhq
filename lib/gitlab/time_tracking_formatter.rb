# frozen_string_literal: true

module Gitlab
  module TimeTrackingFormatter
    extend self

    # We may want to configure it through project settings in a future version.
    CUSTOM_DAY_AND_MONTH_LENGTH = { hours_per_day: 8, days_per_month: 20 }.freeze

    def parse(string)
      string = string.sub(/\A-/, '')

      seconds =
        begin
          ChronicDuration.parse(
            string,
            CUSTOM_DAY_AND_MONTH_LENGTH.merge(default_unit: 'hours'))
        rescue
          nil
        end

      seconds *= -1 if seconds && Regexp.last_match
      seconds
    end

    def output(seconds)
      ChronicDuration.output(
        seconds,
        CUSTOM_DAY_AND_MONTH_LENGTH.merge(
          format: :short,
          limit_to_hours: limit_to_hours_setting,
          weeks: true))
    rescue
      nil
    end

    private

    def limit_to_hours_setting
      Gitlab::CurrentSettings.time_tracking_limit_to_hours
    end
  end
end
