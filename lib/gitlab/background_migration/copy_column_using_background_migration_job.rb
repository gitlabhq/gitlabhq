# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Background migration that updates the value of one or more
    # columns using the value of other columns in the same table.
    #
    # - The {start_id, end_id} arguments are at the start so that it can be used
    #   with `queue_batched_background_migration`
    # - Uses sub-batching so that we can keep each update's execution time at
    #   low 100s ms, while being able to update more records per 2 minutes
    #   that we allow background migration jobs to be scheduled one after the other
    # - We skip the NULL checks as they may result in not using an index scan
    # - The table that is migrated does _not_ need `id` as the primary key
    #   We use the provided primary_key column to perform the update.
    class CopyColumnUsingBackgroundMigrationJob
      include Gitlab::Database::DynamicModelHelpers

      # start_id - The start ID of the range of rows to update.
      # end_id - The end ID of the range of rows to update.
      # batch_table - The name of the table that contains the columns.
      # batch_column - The name of the column we use to batch over the table.
      # sub_batch_size - We don't want updates to take more than ~100ms
      #                  This allows us to run multiple smaller batches during
      #                  the minimum 2.minute interval that we can schedule jobs
      # pause_ms - The number of milliseconds to sleep between each subbatch execution.
      # copy_from - List of columns containing the data to copy.
      # copy_to - List of columns to copy the data to. Order must match the order in `copy_from`.
      def perform(start_id, end_id, batch_table, batch_column, sub_batch_size, pause_ms, copy_from, copy_to)
        copy_from = Array.wrap(copy_from)
        copy_to = Array.wrap(copy_to)

        raise ArgumentError, 'number of source and destination columns must match' unless copy_from.count == copy_to.count

        assignment_clauses = column_assignment_clauses(copy_from, copy_to)

        parent_batch_relation = relation_scoped_to_range(batch_table, batch_column, start_id, end_id)

        parent_batch_relation.each_batch(column: batch_column, of: sub_batch_size) do |sub_batch|
          batch_metrics.time_operation(:update_all) do
            sub_batch.update_all(assignment_clauses)
          end

          pause_ms = 0 if pause_ms < 0
          sleep(pause_ms * 0.001)
        end
      end

      def batch_metrics
        @batch_metrics ||= Gitlab::Database::BackgroundMigration::BatchMetrics.new
      end

      private

      def connection
        ActiveRecord::Base.connection
      end

      def relation_scoped_to_range(source_table, source_key_column, start_id, stop_id)
        define_batchable_model(source_table).where(source_key_column => start_id..stop_id)
      end

      def column_assignment_clauses(copy_from, copy_to)
        assignments = copy_from.zip(copy_to).map do |from_column, to_column|
          from_column = connection.quote_column_name(from_column)
          to_column = connection.quote_column_name(to_column)

          "#{to_column} = #{from_column}"
        end

        assignments.join(', ')
      end
    end
  end
end
