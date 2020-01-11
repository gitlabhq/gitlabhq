# frozen_string_literal: true

module Gitlab
  module SidekiqLogging
    class JSONFormatter
      TIMESTAMP_FIELDS = %w[created_at enqueued_at started_at retried_at failed_at completed_at].freeze

      def call(severity, timestamp, progname, data)
        output = {
          severity: severity,
          time: timestamp.utc.iso8601(3)
        }

        case data
        when String
          output[:message] = data
        when Hash
          convert_to_iso8601!(data)
          output.merge!(data)
        end

        output.to_json + "\n"
      end

      private

      def convert_to_iso8601!(payload)
        TIMESTAMP_FIELDS.each do |key|
          value = payload[key]
          payload[key] = format_time(value) if value.present?
        end
      end

      def format_time(timestamp)
        return timestamp unless timestamp.is_a?(Numeric)

        Time.at(timestamp).utc.iso8601(3)
      end
    end
  end
end
