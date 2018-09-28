module Gitlab
  module SidekiqLogging
    class JSONFormatter
      def call(severity, timestamp, progname, data)
        output = {
          severity: severity,
          time: timestamp.utc.iso8601(3)
        }

        case data
        when String
          output[:message] = data
        when Hash
          output.merge!(data)
        end

        output.to_json + "\n"
      end
    end
  end
end
