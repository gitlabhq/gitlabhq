# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    module BatchingStrategies
      # Generic batching class for use with a BatchedBackgroundMigration.
      # Batches over the given table and column combination, returning the MIN() and MAX()
      # values for the next batch as an array.
      #
      # If no more batches exist in the table, returns nil.
      class PrimaryKeyBatchingStrategy < BaseStrategy
        include Gitlab::Database::DynamicModelHelpers

        # Finds and returns the next batch in the table.
        #
        # table_name - The table to batch over
        # column_name - The column to batch over
        # batch_min_value - The minimum value which the next batch will start at
        # batch_size - The size of the next batch
        # job_arguments - The migration job arguments
        # job_class - The migration job class
        # rubocop:disable Metrics/AbcSize -- temporarily contains two branches for cursor and non-cursor batching
        def next_batch(table_name, column_name, batch_min_value:, batch_size:, job_arguments:, job_class: nil)
          base_class = Gitlab::Database.application_record_for_connection(connection)
          model_class = define_batchable_model(table_name, connection: connection, base_class: base_class)
          next_batch_bounds = nil

          # rubocop:disable Lint/UnreachableLoop -- we need to use each_batch to pull one batch out
          if job_class.cursor?
            cursor_columns = job_class.cursor_columns

            Gitlab::Pagination::Keyset::Iterator.new(
              scope: model_class.order(cursor_columns),
              cursor: cursor_columns.zip(batch_min_value).to_h
            ).each_batch(of: batch_size, load_batch: false) do |batch|
              break unless batch.first && batch.last # skip if the batch is empty for some reason

              next_batch_bounds = [batch.first.values_at(cursor_columns), batch.last.values_at(cursor_columns)]
              break
            end
          else
            arel_column = model_class.arel_table[column_name]
            relation = model_class.where(arel_column.gteq(batch_min_value))
            reset_order = true

            if job_class
              relation = filter_batch(relation,
                table_name: table_name, column_name: column_name,
                job_class: job_class, job_arguments: job_arguments
              )
              reset_order = job_class.reset_order if job_class.respond_to?(:reset_order)
            end

            relation.each_batch(of: batch_size, column: column_name, reset_order: reset_order) do |batch|
              next_batch_bounds = batch.pick(arel_column.minimum, arel_column.maximum)

              break
            end
          end
          # rubocop:enable Lint/UnreachableLoop

          next_batch_bounds
        end
        # rubocop:enable Metrics/AbcSize

        private

        def filter_batch(relation, table_name:, column_name:, job_class:, job_arguments: [])
          return relation unless job_class.respond_to?(:generic_instance)

          job = job_class.generic_instance(
            batch_table: table_name, batch_column: column_name,
            job_arguments: job_arguments, connection: connection
          )

          job.filter_batch(relation)
        end
      end
    end
  end
end
