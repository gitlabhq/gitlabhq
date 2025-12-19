# frozen_string_literal: true

module Gitlab
  module Database
    class RecordCountMonitor
      THRESHOLD = 1_000

      def self.subscribe
        return if @subscribed

        ActiveSupport::Notifications.subscribe('sql.active_record') do |event|
          next unless event.payload[:row_count]
          next if event.payload[:row_count] <= THRESHOLD

          warn_large_result_set(event.payload)
        end

        @subscribed = true
      end

      def self.warn_large_result_set(payload)
        message = "Query fetched #{payload[:row_count]} rows (threshold: #{THRESHOLD})"
        message += "\nSQL: #{payload[:sql]}" if payload[:sql]

        Gitlab::AppLogger.warn(message)
      end
    end
  end
end
