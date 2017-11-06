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
        { duration: formatted_duration, calls: calls }
      end

      private

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
