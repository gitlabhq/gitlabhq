# frozen_string_literal: true

module Peek
  module Views
    class Rugged < View
      def duration
        ::Gitlab::RuggedInstrumentation.query_time
      end

      def calls
        ::Gitlab::RuggedInstrumentation.query_count
      end

      def results
        return {} unless calls > 0

        {
          duration: formatted_duration,
          calls: calls,
          details: details
        }
      end

      private

      def details
        ::Gitlab::RuggedInstrumentation.list_call_details
          .sort { |a, b| b[:duration] <=> a[:duration] }
          .map(&method(:format_call_details))
      end

      def format_call_details(call)
        call.merge(duration: (call[:duration] * 1000).round(3),
                   args: format_args(call[:args]))
      end

      def format_args(args)
        args.map do |arg|
          # Needed to avoid infinite as_json calls
          if arg.is_a?(Gitlab::Git::Repository)
            arg.to_s
          else
            arg
          end
        end
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
