# frozen_string_literal: true

module Gitlab
  module Pagination
    module Keyset
      # This class transforms the `order()` values from an Activerecord scope into a
      # Gitlab::Pagination::Keyset::Order instance so the query later can be  used in
      # keyset pagination.
      #
      # Return values:
      # [transformed_scope, true] # true indicates that the new scope was successfully built
      # [original_scope, false] # false indicates that the order values are not supported in this class
      class SimpleOrderBuilder
        def self.build(scope)
          new(scope: scope).build
        end

        def initialize(scope:)
          @scope = scope
          # We need to run 'compact' because 'nil' is not removed from order_values
          # in some cases due to the use of 'default_scope'.
          @order_values = scope.order_values.compact
          @model_class = scope.model
          @arel_table = @model_class.arel_table
          # Support cases where a single logical primary key has been specified, but also cases where there is a true
          # composite primary key
          @primary_keys = if @model_class.primary_key.nil?
                            @model_class.connection.primary_keys(@model_class.table_name)
                          else
                            Array.wrap(@model_class.primary_key)
                          end
        end

        def build_order
          order = if order_values.empty?
                    primary_key_descending_order
                  elsif Gitlab::Pagination::Keyset::Order.keyset_aware?(scope)
                    Gitlab::Pagination::Keyset::Order.extract_keyset_order_object(scope)
                  # Ordered by a primary key. Ex. 'ORDER BY id'.
                  elsif ordered_by_primary_key?
                    primary_key_order
                  elsif ordered_by_primary_key_prefix?
                    primary_key_order_from_prefix
                  # Ordered by one non-primary table column. Ex. 'ORDER BY created_at'.
                  elsif ordered_by_other_columns?
                    columns_with_tie_breaker_order(order_values)
                  # Ordered by two table columns with the last column as a tie breaker. Ex. 'ORDER BY created, id ASC'.
                  elsif ordered_by_other_columns_with_tie_breaker?
                    tie_breaker_attribute = order_values.last

                    tie_breaker_column_order = Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
                      attribute_name: model_class.primary_key,
                      order_expression: tie_breaker_attribute
                    )

                    columns_with_tie_breaker_order(order_values[0...-1], tie_breaker_column_order)
                  end

          order ? [order, true] : [nil, false]
        end

        def build
          keyset_order, success = build_order
          success ? [scope.reorder!(keyset_order), success] : [scope, false]
        end

        private

        attr_reader :scope, :order_values, :model_class, :arel_table, :primary_keys

        def table_column?(name)
          model_class.column_names.include?(name.to_s)
        end

        def primary_keys?(attributes)
          attrs_as_strings = attributes.map(&:to_s)
          primary_keys.all? { |pk| attrs_as_strings.include?(arel_table[pk].to_s) }
        end

        def lower_named_function?(attribute)
          attribute.is_a?(Arel::Nodes::NamedFunction) && attribute.name&.downcase == 'lower'
        end

        def arel_nulls?(order_value)
          return unless order_value.is_a?(Arel::Nodes::NullsLast) || order_value.is_a?(Arel::Nodes::NullsFirst)

          column_name = order_value.try(:expr).try(:expr).try(:name)

          table_column?(column_name)
        end

        def supported_column?(order_value)
          return true if arel_nulls?(order_value)

          attribute = order_value.try(:expr)
          return unless attribute

          if lower_named_function?(attribute)
            attribute.expressions.one? && attribute.expressions.first.respond_to?(:name) && table_column?(attribute.expressions.first.name)
          else
            attribute.respond_to?(:name) && table_column?(attribute.name)
          end
        end

        def nullability(order_value, attribute_name)
          nullable = model_class.nullable_column?(attribute_name)

          if nullable && order_value.is_a?(Arel::Nodes::Ascending)
            :nulls_last
          elsif nullable && order_value.is_a?(Arel::Nodes::Descending)
            :nulls_first
          else
            :not_nullable
          end
        end

        def primary_key_descending_order
          column_definitions = primary_keys.map do |pk|
            Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
              attribute_name: pk,
              order_expression: arel_table[pk].desc
            )
          end
          Gitlab::Pagination::Keyset::Order.build(column_definitions)
        end

        def primary_key_order
          # This code path is only called if ordered_by_primary_key? returns true
          # in .build(), thus we know that the order values are already the primary keys, and
          # we can simply associate them with their columns here.

          Gitlab::Pagination::Keyset::Order.build(
            order_values.map { |ov| column(ov) }
          )
        end

        def primary_key_order_from_prefix
          suffix_order = order_values.last.is_a?(Arel::Nodes::Ascending) ? :asc : :desc
          Gitlab::Pagination::Keyset::Order.build(
            primary_keys.zip(order_values).map do |pk, order_value|
              expr = if order_value
                       order_value
                     elsif suffix_order == :asc
                       arel_table[pk].asc
                     else # suffix_order == :desc
                       arel_table[pk].desc
                     end

              Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
                attribute_name: pk,
                order_expression: expr
              )
            end
          )
        end

        def columns_with_tie_breaker_order(order_values, tie_breaker_column_order = default_tie_breaker_column_order)
          other_columns = order_values.map { |order_value| column(order_value) }

          Gitlab::Pagination::Keyset::Order.build(
            [
              *other_columns,
              *tie_breaker_column_order
            ])
        end

        def column(order_value)
          return nulls_order_column(order_value) if arel_nulls?(order_value)
          return lower_named_function_column(order_value) if lower_named_function?(order_value.expr)

          attribute_name = order_value.expr.name

          Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
            attribute_name: attribute_name,
            order_expression: order_value,
            nullable: nullability(order_value, attribute_name)
          )
        end

        def nulls_order_column(order_value)
          attribute = order_value.expr.expr

          Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
            attribute_name: attribute.name,
            column_expression: attribute,
            order_expression: order_value,
            reversed_order_expression: order_value.reverse,
            order_direction: order_value.expr.direction,
            nullable: order_value.is_a?(Arel::Nodes::NullsLast) ? :nulls_last : :nulls_first
          )
        end

        def lower_named_function_column(order_value)
          attribute_name = order_value.expr.expressions.first.name

          Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
            attribute_name: attribute_name,
            column_expression: Arel::Nodes::NamedFunction.new("LOWER", [model_class.arel_table[attribute_name]]),
            order_expression: order_value,
            nullable: nullability(order_value, attribute_name)
          )
        end

        def ordered_by_primary_key?
          return unless order_values.count == primary_keys.count

          order_value_names = order_values.map { |ov| ov.try(:expr) }
          primary_keys?(order_value_names)
        end

        def ordered_by_primary_key_prefix?
          order_values.zip(primary_keys).all? do |(ov, pk)|
            ov.try(:expr) == arel_table[pk]
          end
        end

        def ordered_by_other_columns?
          return unless order_values.size >= 1 && !has_tie_breaker?

          supported_columns?(order_values)
        end

        def ordered_by_other_columns_with_tie_breaker?
          return unless order_values.size >= 2 && supported_columns?(order_values[0...-1])

          has_tie_breaker?
        end

        def has_tie_breaker?
          tie_breaker_attributes = order_values.map { |ov| ov.try(:expr) }.last(primary_keys.count)

          primary_keys?(tie_breaker_attributes)
        end

        def supported_columns?(order_values)
          order_values.all? { |order_value| supported_column?(order_value) }
        end

        def default_tie_breaker_column_order
          primary_keys.map do |pk|
            Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
              attribute_name: pk,
              order_expression: arel_table[pk].desc
            )
          end
        end
      end
    end
  end
end
