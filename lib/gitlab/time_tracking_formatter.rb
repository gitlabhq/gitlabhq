module Gitlab
  module TimeTrackingFormatter
    extend self

    def parse(string)
      ChronicDuration.parse(string, default_unit: 'hours')
    rescue ChronicDuration::DurationParseError
      nil
    end

    def output(seconds)
      ChronicDuration.output(seconds, format: :short, limit_to_hours: false, weeks: true)
    end
  end
end
