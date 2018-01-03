module Gitlab
  module Metrics
    # Mocks ::Prometheus::Client::Metric and all derived metrics
    class NullMetric
      def method_missing(name, *args, &block)
        nil
      end
    end
  end
end
