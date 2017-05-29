module Gitlab
  module Metrics
    # Mocks ::Prometheus::Client::Metric and all derived metrics
    class NullMetric
      def method_missing(name, *args, &block)
        nil
      end

      # these methods shouldn't be called when metrics are disabled
      def get(*args)
        raise NotImplementedError
      end

      def values(*args)
        raise NotImplementedError
      end
    end
  end
end
