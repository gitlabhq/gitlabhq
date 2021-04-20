# frozen_string_literal: true

module Gitlab
  module Graphql
    module Pagination
      module Keyset
        module Conditions
          class BaseCondition
            # @param [Arel::Table] arel_table for the relation being ordered
            # @param [Array<OrderInfo>] order_list of extracted orderings
            # @param [Array] values from the decoded cursor
            # @param [Array<String>] operators determining sort comparison
            # @param [Symbol] before_or_after indicates whether we want
            #        items :before the cursor or :after the cursor
            def initialize(arel_table, order_list, values, operators, before_or_after)
              @arel_table = arel_table
              @order_list = order_list
              @values = values
              @operators = operators
              @before_or_after = before_or_after

              @before_or_after = :after unless [:after, :before].include?(@before_or_after)
            end

            def build
              raise NotImplementedError
            end

            private

            attr_reader :arel_table, :order_list, :values, :operators, :before_or_after

            def table_condition(order_info, value, operator)
              if order_info.named_function
                target = order_info.named_function

                if target.try(:name)&.casecmp('lower') == 0
                  value = value&.downcase
                end
              else
                target = arel_table[order_info.attribute_name]
              end

              case operator
              when '>'
                target.gt(value)
              when '<'
                target.lt(value)
              when '='
                target.eq(value)
              when 'is_null'
                target.eq(nil)
              when 'is_not_null'
                target.not_eq(nil)
              end
            end
          end
        end
      end
    end
  end
end
