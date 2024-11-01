# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    module BatchingStrategies
      # This strategy provides an efficient way to iterate over columns with non-distinct values.
      # A common use case would be iterating over a foreign key columns, for example issues.project_id
      class LooseIndexScanBatchingStrategy < BaseStrategy
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
          next_batch_bounds = nil

          relation.distinct_each_batch(of: batch_size, column: column_name) do |batch|
            next_batch_bounds = batch.pick(Arel.sql("MIN(#{quoted_column_name}), MAX(#{quoted_column_name})"))

            break
          end

          next_batch_bounds
        end
      end
    end
  end
end
