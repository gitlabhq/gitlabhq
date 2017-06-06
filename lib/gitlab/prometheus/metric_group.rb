module Gitlab
  module Prometheus
    class MetricGroup
      attr_reader :priority, :name
      attr_accessor :metrics

      def initialize(name:, priority:, metrics: [])
        @name = name
        @priority = priority
        @metrics = metrics
      end

      def self.all
        AdditionalMetricsParser.load_groups_from_yaml
      end
    end
  end
end
