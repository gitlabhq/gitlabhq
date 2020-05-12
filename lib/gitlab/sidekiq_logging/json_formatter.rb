# frozen_string_literal: true

# This is needed for sidekiq-cluster
require 'json'

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
          convert_retry_to_integer!(data)
          stringify_args!(data)
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

      def convert_retry_to_integer!(payload)
        payload['retry'] =
          case payload['retry']
          when Integer
            payload['retry']
          when false, nil
            0
          when true
            Sidekiq::JobRetry::DEFAULT_MAX_RETRY_ATTEMPTS
          else
            -1
          end
      end

      def stringify_args!(payload)
        payload['args'] = Gitlab::Utils::LogLimitedArray.log_limited_array(payload['args'].map(&:to_s)) if payload['args']
      end
    end
  end
end
