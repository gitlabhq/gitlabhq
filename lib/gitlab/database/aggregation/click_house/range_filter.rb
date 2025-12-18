# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      module ClickHouse
        class RangeFilter < FilterDefinition
          private

          def apply(query_builder, filter_config)
            if merge_column?
              query_builder.having(column(query_builder).between(filter_config[:values]))
            else
              query_builder.where(column(query_builder).between(filter_config[:values]))
            end
          end
        end
      end
    end
  end
end
