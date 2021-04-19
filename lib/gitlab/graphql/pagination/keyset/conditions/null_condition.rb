# frozen_string_literal: true

module Gitlab
  module Graphql
    module Pagination
      module Keyset
        module Conditions
          class NullCondition < BaseCondition
            def build
              [first_attribute_condition, final_condition].join
            end

            private

            # ex: "(relative_position IS NULL AND id > 500)"
            def first_attribute_condition
              <<~SQL
                (
                  #{table_condition(order_list.first, nil, 'is_null').to_sql}
                  AND
                  #{table_condition(order_list[1], values[1], operators[1]).to_sql}
                )
              SQL
            end

            # ex: " OR (relative_position IS NOT NULL)"
            def final_condition
              if before_or_after == :before
                <<~SQL
                  OR (#{table_condition(order_list.first, nil, 'is_not_null').to_sql})
                SQL
              end
            end
          end
        end
      end
    end
  end
end
