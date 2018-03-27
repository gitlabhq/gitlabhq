module Peek
  module Views
    class Gitaly < View
      def duration
        ::Gitlab::GitalyClient.query_time
      end

      def calls
        ::Gitlab::GitalyClient.get_request_count
      end

      def results
        {
          duration: formatted_duration,
          calls: calls,
          details: details
        }
      end

      private

      def details
        ::Gitlab::GitalyClient.list_call_details
          .values
          .sort { |a, b| b[:duration] <=> a[:duration] }
          .map(&method(:format_call_details))
      end

      def format_call_details(call)
        pretty_request = call[:request]&.reject { |k, v| v.blank? }.to_h.pretty_inspect

        call.merge(duration: (call[:duration] * 1000).round(3),
                   request: pretty_request || {})
      end

      def formatted_duration
        ms = duration * 1000
        if ms >= 1000
          "%.2fms" % ms
        else
          "%.0fms" % ms
        end
      end

      def setup_subscribers
        subscribe 'start_processing.action_controller' do
          ::Gitlab::GitalyClient.query_time = 0
        end
      end
    end
  end
end
