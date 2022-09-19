# frozen_string_literal: true

module Gitlab
  module Database
    class BatchAverageCounter
      COLUMN_FALLBACK = 0
      DEFAULT_BATCH_SIZE = 1_000
      FALLBACK = -1
      MAX_ALLOWED_LOOPS = 10_000
      OFFSET_BY_ONE = 1
      SLEEP_TIME_IN_SECONDS = 0.01 # 10 msec sleep

      attr_reader :relation, :column

      def initialize(relation, column)
        @relation = relation
        @column = wrap_column(relation, column)
      end

      def count(batch_size: nil)
        raise 'BatchAverageCounter can not be run inside a transaction' if transaction_open?

        batch_size = batch_size.presence || DEFAULT_BATCH_SIZE

        start  = column_start
        finish = column_finish

        total_sum = 0
        total_records = 0

        batch_start = start

        while batch_start < finish
          begin
            batch_end      = [batch_start + batch_size, finish].min
            batch_relation = build_relation_batch(batch_start, batch_end)

            # We use `sum` and `count` instead of `average` here to not run into an "average of averages"
            # problem as batches will have different sizes, so we are essentially summing up the values for
            # each batch separately, and then dividing that result on the total number of records.
            batch_sum, batch_count = batch_relation.pick(column.sum, column.count)

            total_sum     += batch_sum.to_i
            total_records += batch_count

            batch_start = batch_end
          rescue ActiveRecord::QueryCanceled => error # rubocop:disable Database/RescueQueryCanceled
            # retry with a safe batch size & warmer cache
            if batch_size >= 2 * DEFAULT_BATCH_SIZE
              batch_size /= 2
            else
              log_canceled_batch_fetch(batch_start, batch_relation.to_sql, error)

              return FALLBACK
            end
          end

          sleep(SLEEP_TIME_IN_SECONDS)
        end

        return FALLBACK if total_records == 0

        total_sum.to_f / total_records
      end

      private

      def column_start
        relation.unscope(:group, :having).minimum(column) || COLUMN_FALLBACK
      end

      def column_finish
        (relation.unscope(:group, :having).maximum(column) || COLUMN_FALLBACK) + OFFSET_BY_ONE
      end

      def build_relation_batch(start, finish)
        relation.where(column.between(start...finish))
      end

      def log_canceled_batch_fetch(batch_start, query, error)
        Gitlab::AppJsonLogger
          .error(
            event: 'batch_count',
            relation: relation.table_name,
            operation: 'average',
            start: batch_start,
            query: query,
            message: "Query has been canceled with message: #{error.message}"
          )
      end

      def transaction_open?
        relation.connection.transaction_open?
      end

      def wrap_column(relation, column)
        return column if column.is_a?(Arel::Attributes::Attribute)

        relation.arel_table[column]
      end
    end
  end
end
