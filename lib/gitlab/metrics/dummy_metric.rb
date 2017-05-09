module Gitlab
  module Metrics
    # Mocks ::Prometheus::Client::Metric and all derived metrics
    class DummyMetric
      def get(*args)
        raise NotImplementedError
      end

      def values(*args)
        raise NotImplementedError
      end

      # counter
      def increment(*args)
        # noop
      end

      # gauge
      def set(*args)
        # noop
      end

      # histogram / summary
      def observe(*args)
        # noop
      end
    end
  end
end
