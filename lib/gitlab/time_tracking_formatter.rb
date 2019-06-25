# frozen_string_literal: true

module Gitlab
  module TimeTrackingFormatter
    extend self

    def parse(string)
      with_custom_config do
        string = string.sub(/\A-/, '')

        seconds = ChronicDuration.parse(string, default_unit: 'hours') rescue nil
        seconds *= -1 if seconds && Regexp.last_match
        seconds
      end
    end

    def output(seconds)
      with_custom_config do
        ChronicDuration.output(seconds, format: :short, limit_to_hours: limit_to_hours_setting, weeks: true) rescue nil
      end
    end

    private

    def with_custom_config
      # We may want to configure it through project settings in a future version.
      ChronicDuration.hours_per_day = 8
      ChronicDuration.days_per_week = 5

      result = yield

      ChronicDuration.hours_per_day = 24
      ChronicDuration.days_per_week = 7

      result
    end

    def limit_to_hours_setting
      Gitlab::CurrentSettings.time_tracking_limit_to_hours
    end
  end
end
