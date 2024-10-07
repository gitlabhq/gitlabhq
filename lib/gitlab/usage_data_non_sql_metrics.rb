# frozen_string_literal: true

module Gitlab
  class UsageDataNonSqlMetrics < UsageData
    SQL_METRIC_DEFAULT = -3

    class << self
      def add_metric(metric, time_frame: 'none', options: {})
        metric_class = "Gitlab::Usage::Metrics::Instrumentations::#{metric}".constantize

        metric_class.new(time_frame: time_frame, options: options).instrumentation
      end

      def count(relation, column = nil, batch: true, batch_size: nil, start: nil, finish: nil)
        SQL_METRIC_DEFAULT
      end

      def distinct_count(relation, column = nil, batch: true, batch_size: nil, start: nil, finish: nil)
        SQL_METRIC_DEFAULT
      end

      def estimate_batch_distinct_count(relation, column = nil, batch_size: nil, start: nil, finish: nil)
        SQL_METRIC_DEFAULT
      end

      def sum(relation, column, batch_size: nil, start: nil, finish: nil)
        SQL_METRIC_DEFAULT
      end

      def histogram(relation, column, buckets:, bucket_size: buckets.size)
        SQL_METRIC_DEFAULT
      end

      def add(*args)
        SQL_METRIC_DEFAULT
      end

      def maximum_id(model, column = nil); end

      def minimum_id(model, column = nil); end
    end
  end
end
