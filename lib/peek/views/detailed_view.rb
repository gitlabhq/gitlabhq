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

      private

      def duration
        raise NotImplementedError
      end

      def calls
        raise NotImplementedError
      end

      def call_details
        raise NotImplementedError
      end

      def format_call_details(call)
        raise NotImplementedError
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
