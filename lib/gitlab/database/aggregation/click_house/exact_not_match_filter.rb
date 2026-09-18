# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      module ClickHouse
        # Excludes rows whose column value is in the given list (`NOT IN`).
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
