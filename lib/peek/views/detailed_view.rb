# frozen_string_literal: true

module Peek
  module Views
    class DetailedView < View
      def self.thresholds
        {}
      end

      def results
        {
          duration: format_duration(duration),
          calls: calls,
          details: details,
          warnings: warnings
        }
      end

      def detail_store
        ::Gitlab::SafeRequestStore["#{key}_call_details".to_sym] ||= []
      end

      private

      def duration
        detail_store.sum { |entry| entry[:duration] } * 1000
      end

      def calls
        detail_store.count
      end

      def details
        call_details
          .sort { |a, b| b[:duration] <=> a[:duration] }
          .map { |call| format_call_details(call) }
      end

      def warnings
        [
          warning_for(calls, self.class.thresholds[:calls], label: "#{key} calls"),
          warning_for(duration, self.class.thresholds[:duration], label: "#{key} duration")
        ].flatten.compact
      end

      def call_details
        detail_store
      end

      def format_call_details(call)
        duration = (call[:duration] * 1000).round(3)

        call.merge(duration: duration,
          warnings: warning_for(duration, self.class.thresholds[:individual_call]))
      end

      def warning_for(actual, threshold, label: nil)
        if threshold && actual > threshold
          prefix = "#{label}: " if label

          ["#{prefix}#{actual} over #{threshold}"]
        else
          []
        end
      end

      def format_duration(ms)
        if ms >= 1000
          "%.2fms" % ms
        else
          "%.0fms" % ms
        end
      end
    end
  end
end
