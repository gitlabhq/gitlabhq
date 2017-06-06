module Gitlab
  module Prometheus
    class Metric
      attr_reader :group, :title, :required_metrics, :weight, :y_label, :queries

      def initialize(title, required_metrics, weight, y_label, queries = [])
        @title = title
        @required_metrics = required_metrics
        @weight = weight
        @y_label = y_label || 'Values'
        @queries = queries
      end
    end
  end
end
