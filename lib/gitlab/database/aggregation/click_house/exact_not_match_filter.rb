# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      module ClickHouse
        # Excludes rows whose column value is in the given list (`NOT IN`).
        #
        # Two consequences are easy to miss:
        #
        # - Rows where the column is NULL are excluded as well, because `NULL NOT IN (...)` is NULL
        #   and both `WHERE` and `HAVING` treat that as false. A nullable column therefore returns
        #   only the rows that have a value.
        # - An empty value list matches every row, so a formatter that discards unrecognized input
        #   turns the filter into a no-op rather than an empty result.
        class ExactNotMatchFilter < FilterDefinition
          def identifier
            :"#{name}_not"
          end

          private

          def apply(query_builder, filter_config)
            if merge_column?
              query_builder.having(column(query_builder).not_in(filter_config[:values]))
            else
              query_builder.where(column(query_builder).not_in(filter_config[:values]))
            end
          end
        end
      end
    end
  end
end
