# frozen_string_literal: true

# This is needed for sidekiq-cluster
require 'json'
require 'sidekiq/job_retry'

module Gitlab
  module SidekiqLogging
    class JSONFormatter
      TIMESTAMP_FIELDS = %w[created_at scheduled_at enqueued_at started_at retried_at failed_at completed_at].freeze

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

          # jobstr is redundant and can include information we wanted to
          # exclude (like arguments)
          output.delete(:jobstr)

          convert_to_iso8601!(output)
          convert_retry_to_integer!(output)
          process_args!(output)
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

      def process_args!(payload)
        return unless payload['args']

        payload['args'] = ::Gitlab::ErrorTracking::Processor::SidekiqProcessor
                            .loggable_arguments(payload['args'], payload['class'])
      end
    end
  end
end
