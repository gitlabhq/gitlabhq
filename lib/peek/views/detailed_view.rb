# frozen_string_literal: true

module Peek
  module Views
    class DetailedView < View
      def results
        {
          duration: formatted_duration,
          calls: calls,
          details: details
        }
      end

      def detail_store
        ::Gitlab::SafeRequestStore["#{key}_call_details"] ||= []
      end

      private

      def duration
        detail_store.map { |entry| entry[:duration] }.sum # rubocop:disable CodeReuse/ActiveRecord
      end

      def calls
        detail_store.count
      end

      def call_details
        detail_store
      end

      def format_call_details(call)
        call.merge(duration: (call[:duration] * 1000).round(3))
      end

      def details
        call_details
          .sort { |a, b| b[:duration] <=> a[:duration] }
          .map(&method(:format_call_details))
      end

      def formatted_duration
        ms = duration * 1000

        if ms >= 1000
          "%.2fms" % ms
        else
          "%.0fms" % ms
        end
      end
    end
  end
end
