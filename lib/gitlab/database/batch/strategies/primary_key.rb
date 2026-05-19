# frozen_string_literal: true

module Gitlab
  module Database
    module Batch
      module Strategies
        # Batches over the given table and column combination, returning the MIN() and MAX()
        # values for the next batch as an array of array (compatible with composite PK)
        #
        # If no more batches exist in the table, returns nil.
        class PrimaryKey < BaseStrategy
          include Gitlab::Database::DynamicModelHelpers

          # Finds and returns the next batch in the table.
          #
          # table_name - The table to batch over
          # batch_min_value - The minimum value which the next batch will start at
          # batch_size - The size of the next batch
          # job_class - The migration job class
          def next_batch(table_name, batch_min_value:, batch_size:, job_class: nil, job_arguments: [])
            base_class = Gitlab::Database.application_record_for_connection(connection)
            model_class = define_batchable_model(table_name, connection: connection, base_class: base_class)

            cursor_columns = job_class.cursor_columns
            scope = apply_scope_to(model_class, job_class, table_name, cursor_columns, job_arguments)
            iterator = create_keyset_iterator(scope, cursor_columns, batch_min_value)

            extract_batch_bounds(iterator, batch_size, cursor_columns)
          end

          private

          def create_keyset_iterator(scope, cursor_columns, batch_min_value)
            arel_table = scope.arel_table
            cursor_expression = Arel::Nodes::Grouping.new(
              cursor_columns.map { |column| arel_table[column] }
            )
            cursor_values = Arel::Nodes::Grouping.new(
              cursor_columns.zip(batch_min_value).map do |column, value|
                Arel::Nodes.build_quoted(value, arel_table[column])
              end
            )

            Gitlab::Pagination::Keyset::Iterator.new(
              scope: scope.where(cursor_expression.gteq(cursor_values)).order(cursor_columns)
            )
          end

          def apply_scope_to(model_class, job_class, table_name, cursor_columns, job_arguments)
            job_instance = job_class.new(
              batch_table: table_name,
              batch_column: cursor_columns,
              sub_batch_size: 0,
              pause_ms: 0,
              connection: connection,
              job_arguments: job_arguments
            )

            job_instance.filter_batch(model_class)
          end

          # rubocop:disable Lint/UnreachableLoop -- we need to use each_batch to pull one batch out
          def extract_batch_bounds(iterator, batch_size, cursor_columns)
            batch_bounds = nil

            iterator.each_batch(of: batch_size, load_batch: false) do |batch|
              break unless valid_batch?(batch)

              batch_bounds = build_batch_bounds(batch, cursor_columns)
              break
            end

            batch_bounds
          end
          # rubocop:enable Lint/UnreachableLoop

          def valid_batch?(batch)
            batch&.first && batch.last
          end

          def build_batch_bounds(batch, cursor_columns)
            [
              batch.first.values_at(cursor_columns),
              batch.last.values_at(cursor_columns)
            ]
          end
        end
      end
    end
  end
end
