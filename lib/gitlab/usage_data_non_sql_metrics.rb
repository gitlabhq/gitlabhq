# frozen_string_literal: true

module Gitlab
  class UsageDataNonSqlMetrics < UsageData
    SQL_METRIC_DEFAULT = -3

    class << self
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

      def maximum_id(model)
      end

      def minimum_id(model)
      end
    end
  end
end
