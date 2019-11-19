# frozen_string_literal: true

module Gitlab
  module Graphql
    module Connections
      module Keyset
        module Conditions
          class BaseCondition
            def initialize(arel_table, names, values, operator, before_or_after)
              @arel_table, @names, @values, @operator, @before_or_after = arel_table, names, values, operator, before_or_after
            end

            def build
              raise NotImplementedError
            end

            private

            attr_reader :arel_table, :names, :values, :operator, :before_or_after

            def table_condition(attribute, value, operator)
              case operator
              when '>'
                arel_table[attribute].gt(value)
              when '<'
                arel_table[attribute].lt(value)
              when '='
                arel_table[attribute].eq(value)
              when 'is_null'
                arel_table[attribute].eq(nil)
              when 'is_not_null'
                arel_table[attribute].not_eq(nil)
              end
            end
          end
        end
      end
    end
  end
end
