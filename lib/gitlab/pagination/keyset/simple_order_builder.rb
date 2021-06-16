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
      # [orginal_scope, false] # false indicates that the order values are not supported in this class
      class SimpleOrderBuilder
        def self.build(scope)
          new(scope: scope).build
        end

        def initialize(scope:)
          @scope = scope
          @order_values = scope.order_values
          @model_class = scope.model
          @arel_table = @model_class.arel_table
          @primary_key = @model_class.primary_key
        end

        def build
          order = if order_values.empty?
                    primary_key_descending_order
                  elsif Gitlab::Pagination::Keyset::Order.keyset_aware?(scope)
                    Gitlab::Pagination::Keyset::Order.extract_keyset_order_object(scope)
                  elsif ordered_by_primary_key?
                    primary_key_order
                  elsif ordered_by_other_column?
                    column_with_tie_breaker_order
                  elsif ordered_by_other_column_with_tie_breaker?
                    tie_breaker_attribute = order_values.second

                    tie_breaker_column_order = Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
                      attribute_name: model_class.primary_key,
                      order_expression: tie_breaker_attribute
                    )

                    column_with_tie_breaker_order(tie_breaker_column_order)
                  end

          order ? [scope.reorder!(order), true] : [scope, false] # [scope, success]
        end

        private

        attr_reader :scope, :order_values, :model_class, :arel_table, :primary_key

        def primary_key_descending_order
          Gitlab::Pagination::Keyset::Order.build([
            Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
              attribute_name: model_class.primary_key,
              order_expression: arel_table[primary_key].desc
            )
          ])
        end

        def primary_key_order
          Gitlab::Pagination::Keyset::Order.build([
            Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
              attribute_name: model_class.primary_key,
              order_expression: order_values.first
            )
          ])
        end

        def column_with_tie_breaker_order(tie_breaker_column_order = default_tie_breaker_column_order)
          order_expression = order_values.first
          attribute_name = order_expression.expr.name

          column_nullable = model_class.columns.find { |column| column.name == attribute_name }.null

          nullable = if column_nullable && order_expression.is_a?(Arel::Nodes::Ascending)
                       :nulls_last
                     elsif column_nullable && order_expression.is_a?(Arel::Nodes::Descending)
                       :nulls_first
                     else
                       :not_nullable
                     end

          Gitlab::Pagination::Keyset::Order.build([
            Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
              attribute_name: attribute_name,
              order_expression: order_expression,
              nullable: nullable,
              distinct: false
            ),
            tie_breaker_column_order
          ])
        end

        def ordered_by_primary_key?
          return unless order_values.one?

          attribute = order_values.first.try(:expr)

          return unless attribute

          arel_table[primary_key].to_s == attribute.to_s
        end

        def ordered_by_other_column?
          return unless order_values.one?

          attribute = order_values.first.try(:expr)

          return unless attribute
          return unless attribute.try(:name)

          model_class.column_names.include?(attribute.name.to_s)
        end

        def ordered_by_other_column_with_tie_breaker?
          return unless order_values.size == 2

          attribute = order_values.first.try(:expr)
          tie_breaker_attribute = order_values.second.try(:expr)

          return unless attribute
          return unless tie_breaker_attribute

          model_class.column_names.include?(attribute.name.to_s) &&
            arel_table[primary_key].to_s == tie_breaker_attribute.to_s
        end

        def default_tie_breaker_column_order
          Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
            attribute_name: model_class.primary_key,
            order_expression: arel_table[primary_key].desc
          )
        end
      end
    end
  end
end
