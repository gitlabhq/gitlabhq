# frozen_string_literal: true

module Gitlab
  module Prometheus
    class MetricGroup
      include ActiveModel::Model

      attr_accessor :name, :priority, :metrics

      validates :name, :priority, :metrics, presence: true

      def self.common_metrics
        all_groups = ::PrometheusMetricsFinder.new(common: true).execute
          .group_by(&:group_title)
          .map do |name, metrics|
            MetricGroup.new(
              name: name,
              priority: metrics.map(&:priority).max,
              metrics: metrics.map(&:to_query_metric)
            )
          end

        all_groups.sort_by(&:priority).reverse
      end

      # EE only
      def self.for_project(_)
        common_metrics
      end
    end
  end
end

Gitlab::Prometheus::MetricGroup.prepend_mod_with('Gitlab::Prometheus::MetricGroup')
