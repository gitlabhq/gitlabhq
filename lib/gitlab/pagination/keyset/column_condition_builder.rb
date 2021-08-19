# frozen_string_literal: true

module Gitlab
  module Pagination
    module Keyset
      class ColumnConditionBuilder
        # This class builds the WHERE conditions for the keyset pagination library.
        # It produces WHERE conditions for one column at a time.
        #
        # Requisite 1: Only the last column (columns.last) is non-nullable and distinct.
        # Requisite 2: Only one column is distinct and non-nullable.
        #
        # Scenario: We want to order by columns named X, Y and Z and build the conditions
        #          used in the WHERE clause of a pagination query using a set of cursor values.
        #   X is the column definition for a nullable column
        #   Y is the column definition for a non-nullable but not distinct column
        #   Z is the column definition for a distinct, non-nullable column used as a tie breaker.
        #
        #   Then the method is initially invoked with these arguments:
        #     columns = [ColumnDefinition for X, ColumnDefinition for Y, ColumnDefinition for Z]
        #     values = { X: x, Y: y, Z: z } => these represent cursor values for pagination
        #                                      (x could be nil since X is nullable)
        #     current_conditions is initialized to [] to store the result during the iteration calls
        #     invoked within the Order#build_where_values method.
        #
        #   The elements of current_conditions are instances of Arel::Nodes and -
        #    will be concatenated using OR or UNION to be used in the WHERE clause.
        #
        #   Example: Let's say we want to build WHERE clause conditions for
        #     ORDER BY X DESC NULLS LAST, Y ASC, Z DESC
        #
        #     Iteration 1:
        #       columns = [X, Y, Z]
        #       At the end, current_conditions should be:
        #         [(Z < z)]
        #
        #     Iteration 2:
        #       columns = [X, Y]
        #       At the end, current_conditions should be:
        #         [(Y > y) OR (Y = y AND Z < z)]
        #
        #     Iteration 3:
        #       columns = [X]
        #       At the end, current_conditions should be:
        #         [((X IS NOT NULL AND Y > y) OR (X IS NOT NULL AND Y = y AND Z < z))
        #           OR
        #          ((x IS NULL) OR (X IS NULL))]
        #
        # Parameters:
        #
        #  - columns: instance of ColumnOrderDefinition
        #  - value: cursor value for the column
        def initialize(column, value)
          @column = column
          @value = value
        end

        def where_conditions(current_conditions)
          return not_nullable_conditions(current_conditions) if column.not_nullable?
          return nulls_first_conditions(current_conditions) if column.nulls_first?

          # Here we are dealing with the case of column_definition.nulls_last?
          # Suppose ORDER BY X DESC NULLS FIRST, Y ASC, Z DESC is the ordering clause
          # and we already have built the conditions for columns Y and Z.
          #
          # We first need a set of conditions to use when x (the value for X) is NULL:
          #   null_conds = [
          #     (x IS NULL AND X IS NULL AND Y<y),
          #     (x IS NULL AND X IS NULL AND Y=y AND Z<z),
          null_conds = current_conditions.map do |conditional|
            Arel::Nodes::And.new([value_is_null, column_is_null, conditional])
          end

          # We then need a set of conditions to use when m has an actual value:
          #   non_null_conds = [
          #     (x IS NOT NULL AND X IS NULL),
          #     (x IS NOT NULL AND X < x)
          #     (x IS NOT NULL AND X = x AND Y > y),
          #     (x IS NOT NULL AND X = x AND Y = y AND Z < z),
          tie_breaking_conds = current_conditions.map do |conditional|
            Arel::Nodes::And.new([column_equals_to_value, conditional])
          end

          non_null_conds = [column_is_null, compare_column_with_value, *tie_breaking_conds].map do |conditional|
            Arel::Nodes::And.new([value_is_not_null, conditional])
          end

          [*null_conds, *non_null_conds]
        end

        private

        # WHEN THE COLUMN IS NON-NULLABLE AND DISTINCT
        #   Per Assumption 1, only the last column can be non-nullable and distinct
        #   (column Z is non-nullable/distinct and comes last in the example).
        #   So the Order#build_where_conditions is being called for the first time with current_conditions = [].
        #
        #   At the end of the call, we should expect:
        #     current_conditions should be [(Z < z)]
        #
        # WHEN THE COLUMN IS NON-NULLABLE BUT NOT DISTINCT
        #   Let's say Z has been processed and we are about to process the column Y next.
        #   (per requisite 1, if a non-nullable but not distinct column is being processed,
        #    at the least, the conditional for the non-nullable/distinct column exists)
        #
        #   At the start of the method call:
        #     current_conditions = [(Z < z)]
        #     comparison_node = (Y < y)
        #     eqaulity_node = (Y = y)
        #
        #   We should add a comparison node for the next column Y, (Y < y)
        #    then break a tie using the previous conditionals, (Y = y AND Z < z)
        #
        #   At the end of the call, we should expect:
        #     current_conditions = [(Y < y), (Y = y AND Z < z)]
        def not_nullable_conditions(current_conditions)
          tie_break_conds = current_conditions.map do |conditional|
            Arel::Nodes::And.new([column_equals_to_value, conditional])
          end

          [compare_column_with_value, *tie_break_conds]
        end

        def nulls_first_conditions(current_conditions)
          # Using the same scenario described earlier,
          # suppose the ordering clause is ORDER BY X DESC NULLS FIRST, Y ASC, Z DESC
          # and we have built the conditions for columns Y and Z in previous iterations:
          #
          #   current_conditions = [(Y > y), (Y = y AND Z < z)]
          #
          # In this branch of the iteration,
          # we first need a set of conditions to use when m (the value for M) is NULL:
          #   null_conds = [
          #     (x IS NULL AND X IS NULL AND Y > y),
          #     (x IS NULL AND X IS NULL AND Y = y AND Z < z),
          #     (x IS NULL AND X IS NOT NULL)]
          #
          # Note that when x has an actual value, say x = 3, null_conds evalutes to FALSE.
          tie_breaking_conds = current_conditions.map do |conditional|
            Arel::Nodes::And.new([column_is_null, conditional])
          end

          null_conds = [*tie_breaking_conds, column_is_not_null].map do |conditional|
            Arel::Nodes::And.new([value_is_null, conditional])
          end

          # We then need a set of conditions to use when m has an actual value:
          #   non_null_conds = [
          #     (x IS NOT NULL AND X < x),
          #     (x IS NOT NULL AND X = x AND Y > y),
          #     (x IS NOT NULL AND X = x AND Y = y AND Z < z)]
          #
          # Note again that when x IS NULL, non_null_conds evaluates to FALSE.
          tie_breaking_conds = current_conditions.map do |conditional|
            Arel::Nodes::And.new([column_equals_to_value, conditional])
          end

          # The combined OR condition (null_where_cond OR non_null_where_cond) will return a correct result -
          # without having to account for whether x is nil or an actual value at the application level.
          non_null_conds = [compare_column_with_value, *tie_breaking_conds].map do |conditional|
            Arel::Nodes::And.new([value_is_not_null, conditional])
          end

          [*null_conds, *non_null_conds]
        end

        def column_equals_to_value
          @equality_node ||= column.column_expression.eq(value)
        end

        def column_is_null
          @column_is_null ||= column.column_expression.eq(nil)
        end

        def column_is_not_null
          @column_is_not_null ||= column.column_expression.not_eq(nil)
        end

        def value_is_null
          @value_is_null ||= build_quoted_value.eq(nil)
        end

        def value_is_not_null
          @value_is_not_null ||= build_quoted_value.not_eq(nil)
        end

        def compare_column_with_value
          if column.descending_order?
            column.column_expression.lt(value)
          else
            column.column_expression.gt(value)
          end
        end

        # Turns the given value to an SQL literal by casting it to the proper format.
        def build_quoted_value
          return value if value.instance_of?(Arel::Nodes::SqlLiteral)

          Arel::Nodes.build_quoted(value, column.column_expression)
        end

        attr_reader :column, :value
      end
    end
  end
end
