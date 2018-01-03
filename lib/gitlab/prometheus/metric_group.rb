module Gitlab
  module Prometheus
    class MetricGroup
      include ActiveModel::Model

      attr_accessor :name, :priority, :metrics
      validates :name, :priority, :metrics, presence: true

      def self.all
        AdditionalMetricsParser.load_groups_from_yaml
      end
    end
  end
end
