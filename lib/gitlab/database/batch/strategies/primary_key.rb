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
          def next_batch(table_name, batch_min_value:, batch_size:, job_class: nil)
            base_class = Gitlab::Database.application_record_for_connection(connection)
            model_class = define_batchable_model(table_name, connection: connection, base_class: base_class)

            cursor_columns = job_class.cursor_columns
            iterator = create_keyset_iterator(model_class, cursor_columns, batch_min_value)

            extract_batch_bounds(iterator, batch_size, cursor_columns)
          end

          private

          def create_keyset_iterator(model_class, cursor_columns, batch_min_value)
            Gitlab::Pagination::Keyset::Iterator.new(
              scope: model_class.order(cursor_columns),
              cursor: cursor_columns.zip(batch_min_value).to_h
            )
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
              batch.first.values_at(*cursor_columns),
              batch.last.values_at(*cursor_columns)
            ]
          end
        end
      end
    end
  end
end
