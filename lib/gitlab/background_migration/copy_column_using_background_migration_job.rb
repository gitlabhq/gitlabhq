# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Background migration that updates the value of a
    # column using the value of another column in the same table.
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

      PAUSE_SECONDS = 0.1

      # start_id - The start ID of the range of rows to update.
      # end_id - The end ID of the range of rows to update.
      # batch_table - The name of the table that contains the columns.
      # batch_column - The name of the column we use to batch over the table.
      # sub_batch_size - We don't want updates to take more than ~100ms
      #                  This allows us to run multiple smaller batches during
      #                  the minimum 2.minute interval that we can schedule jobs
      # copy_from - The column containing the data to copy.
      # copy_to - The column to copy the data to.
      def perform(start_id, end_id, batch_table, batch_column, sub_batch_size, copy_from, copy_to)
        quoted_copy_from = connection.quote_column_name(copy_from)
        quoted_copy_to = connection.quote_column_name(copy_to)

        parent_batch_relation = relation_scoped_to_range(batch_table, batch_column, start_id, end_id)

        parent_batch_relation.each_batch(column: batch_column, of: sub_batch_size) do |sub_batch|
          batch_metrics.time_operation(:update_all) do
            sub_batch.update_all("#{quoted_copy_to}=#{quoted_copy_from}")
          end

          sleep(PAUSE_SECONDS)
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
    end
  end
end
