# frozen_string_literal: true

module InternalEventsCli
  module Subflows
    class DatabaseMetricDefiner
      attr_reader :metric

      def initialize(cli)
        @cli = cli
        @metric = nil
      end

      def run
        @metric = Metric.new
        metric.data_source = 'database'

        # TODO: replace hardcoded assignments https://gitlab.com/gitlab-org/gitlab/-/issues/464066
        metric.instrumentation_class = 'CountIssuesMetric'
        metric.time_frame = %w[7d 28d]
        metric.key_path = 'issues_count'
      end

      private

      attr_reader :cli
    end
  end
end
