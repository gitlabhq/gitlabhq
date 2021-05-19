# frozen_string_literal: true

module Gitlab
  module Graphql
    module Pagination
      module Keyset
        class OrderInfo
          attr_reader :attribute_name, :sort_direction, :named_function

          def initialize(order_value)
            @attribute_name, @sort_direction, @named_function =
              if order_value.is_a?(String)
                extract_nulls_last_order(order_value)
              else
                extract_attribute_values(order_value)
              end
          end

          def operator_for(before_or_after)
            case before_or_after
            when :before
              sort_direction == :asc ? '<' : '>'
            when :after
              sort_direction == :asc ? '>' : '<'
            end
          end

          # Only allow specific node types
          def self.build_order_list(relation)
            order_list = relation.order_values.select do |value|
              supported_order_value?(value)
            end

            order_list.map { |info| OrderInfo.new(info) }
          end

          def self.validate_ordering(relation, order_list)
            if order_list.empty?
              raise ArgumentError, 'A minimum of 1 ordering field is required'
            end

            if order_list.count > 2
              # Keep in mind an order clause for primary key is added if one is not present
              # lib/gitlab/graphql/pagination/keyset/connection.rb:97
              raise ArgumentError, 'A maximum of 2 ordering fields are allowed'
            end

            # make sure the last ordering field is non-nullable
            attribute_name = order_list.last&.attribute_name

            if relation.columns_hash[attribute_name].null
              raise ArgumentError, "Column `#{attribute_name}` must not allow NULL"
            end

            if order_list.last.attribute_name != relation.primary_key
              raise ArgumentError, "Last ordering field must be the primary key, `#{relation.primary_key}`"
            end
          end

          def self.supported_order_value?(order_value)
            return true if order_value.is_a?(Arel::Nodes::Ascending) || order_value.is_a?(Arel::Nodes::Descending)
            return false unless order_value.is_a?(String)

            tokens = order_value.downcase.split

            tokens.last(2) == %w(nulls last) && tokens.count == 4
          end

          private

          def extract_nulls_last_order(order_value)
            tokens = order_value.downcase.split

            column_reference = tokens.first
            sort_direction = tokens[1] == 'asc' ? :asc : :desc

            # Handles the case when the order value is coming from another table.
            # Example: table_name.column_name
            # Query the value using the fully qualified column name: pass table_name.column_name as the named_function
            if fully_qualified_column_reference?(column_reference)
              [column_reference, sort_direction, Arel.sql(column_reference)]
            else
              [column_reference, sort_direction, nil]
            end
          end

          # Example: table_name.column_name
          def fully_qualified_column_reference?(attribute)
            attribute.to_s.count('.') == 1
          end

          def extract_attribute_values(order_value)
            if ordering_by_lower?(order_value)
              [order_value.expr.expressions[0].name.to_s, order_value.direction, order_value.expr]
            elsif ordering_by_case?(order_value)
              ['case_order_value', order_value.direction, order_value.expr]
            elsif ordering_by_array_position?(order_value)
              ['array_position', order_value.direction, order_value.expr]
            else
              [order_value.expr.name, order_value.direction, nil]
            end
          end

          # determine if ordering using LOWER, eg. "ORDER BY LOWER(boards.name)"
          def ordering_by_lower?(order_value)
            order_value.expr.is_a?(Arel::Nodes::NamedFunction) && order_value.expr&.name&.downcase == 'lower'
          end

          # determine if ordering using ARRAY_POSITION, eg. "ORDER BY ARRAY_POSITION(Array[4,3,1,2]::smallint, state)"
          def ordering_by_array_position?(order_value)
            order_value.expr.is_a?(Arel::Nodes::NamedFunction) && order_value.expr&.name&.downcase == 'array_position'
          end

          # determine if ordering using CASE
          def ordering_by_case?(order_value)
            order_value.expr.is_a?(Arel::Nodes::Case)
          end
        end
      end
    end
  end
end

Gitlab::Graphql::Pagination::Keyset::OrderInfo.prepend_mod_with('Gitlab::Graphql::Pagination::Keyset::OrderInfo')
