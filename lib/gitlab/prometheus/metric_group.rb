module Gitlab
  module Prometheus
    class MetricGroup
      include ActiveModel::Model

      attr_accessor :name, :priority, :metrics
      validates :name, :priority, :metrics, presence: true

      def self.common_metrics
        AdditionalMetricsParser.load_groups_from_yaml
      end

      # EE only
      def self.for_project(_)
        common_metrics
      end
    end
  end
end
