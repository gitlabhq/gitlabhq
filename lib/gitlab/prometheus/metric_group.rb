module Gitlab
  module Prometheus
    class MetricGroup
      include ActiveModel::Model

      attr_accessor :name, :priority, :metrics

      validates :name, :priority, :metrics, presence: true

      def self.common_metrics
        ::PrometheusMetric.common.group_by(&:group_title).map do |name, metrics|
          MetricGroup.new(name: name, priority: 0, metrics: metrics.map(&:to_query_metric))
        end
      end

      # EE only
      def self.for_project(_)
        common_metrics
      end
    end
  end
end
