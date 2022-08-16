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
        def next_batch(table_name, column_name, batch_min_value:, batch_size:, job_arguments:, job_class: nil)
          model_class = define_batchable_model(table_name, connection: connection)

          quoted_column_name = model_class.connection.quote_column_name(column_name)
          relation = model_class.where("#{quoted_column_name} >= ?", batch_min_value)

          if job_class
            relation = filter_batch(relation,
              table_name: table_name, column_name: column_name,
              job_class: job_class, job_arguments: job_arguments
            )
          end

          relation = apply_additional_filters(relation, job_arguments: job_arguments, job_class: job_class)
          next_batch_bounds = nil

          relation.each_batch(of: batch_size, column: column_name) do |batch| # rubocop:disable Lint/UnreachableLoop
            next_batch_bounds = batch.pick(Arel.sql("MIN(#{quoted_column_name}), MAX(#{quoted_column_name})"))

            break
          end

          next_batch_bounds
        end

        # Deprecated
        #
        # Use `scope_to` to define additional filters on the migration job class.
        #
        # see https://docs.gitlab.com/ee/development/database/batched_background_migrations.html#adding-additional-filters.
        def apply_additional_filters(relation, job_arguments: [], job_class: nil)
          relation
        end

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
