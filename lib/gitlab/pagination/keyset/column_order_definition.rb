# frozen_string_literal: true

module Gitlab
  module Pagination
    module Keyset
      # This class stores information for one column (or SQL expression) which can be used in an
      # ORDER BY SQL clasue.
      # The goal of this class is to encapsulate all the metadata in one place which are needed to
      # make keyset pagination work in a generalized way.
      #
      # == Arguments
      #
      # **order expression** (Arel::Nodes::Node | String)
      #
      # The actual SQL expression for the ORDER BY clause.
      #
      # Examples:
      #   # Arel column order definition
      #   Project.arel_table[:id].asc # ORDER BY projects.id ASC
      #
      #   # Arel expression, calculated order definition
      #   Arel::Nodes::NamedFunction.new("COALESCE", [Project.arel_table[:issue_count].asc, 0]).asc # ORDER BY COALESCE(projects.issue_count, 0)
      #
      #   # Another Arel expression
      #   Arel::Nodes::Multiplication(Issue.arel_table[:weight], Issue.arel_table[:time_spent]).desc
      #
      #   # Raw string order definition
      #   'issues.type DESC NULLS LAST'
      #
      # **column_expression** (Arel::Nodes::Node | String)
      #
      # Expression for the database column or an expression. This value will be used with logical operations (>, <, =, !=)
      # when building the database query for the next page.
      #
      # Examples:
      #   # Arel column reference
      #   Issue.arel_table[:title]
      #
      #   # Calculated value
      #   Arel::Nodes::Multiplication(Issue.arel_table[:weight], Issue.arel_table[:time_spent])
      #
      # **attribute_name** (String | Symbol)
      #
      # An attribute on the loaded ActiveRecord model where the value can be obtained.
      #
      # Examples:
      #   # Simple attribute definition
      #   attribute_name = :title
      #
      #   # Later on this attribute will be used like this:
      #   my_record = Issue.find(x)
      #   value = my_record[attribute_name] # reads data from the title column
      #
      #   # Calculated value based on an Arel or raw SQL expression
      #
      #   attribute_name = :lowercase_title
      #
      #   # `lowercase_title` is not is not a table column therefore we need to make sure it's available in the `SELECT` clause
      #
      #   my_record = Issue.select(:id, 'LOWER(title) as lowercase_title').last
      #   value = my_record[:lowercase_title]
      #
      # **distinct**
      #
      # Boolean value.
      #
      # Tells us whether the database column contains only distinct values. If the column is covered by
      # a unique index then set to true.
      #
      # **nullable** (:not_nullable | :nulls_last | :nulls_first)
      #
      # Tells us whether the database column is nullable or not. This information can be
      # obtained from the DB schema.
      #
      # If the column is not nullable, set this attribute to :not_nullable.
      #
      # If the column is nullable, then additional information is needed. Based on the ordering, the null values
      # will show up at the top or at the bottom of the resultset.
      #
      # Examples:
      #     # Nulls are showing up at the top (for example: ORDER BY column ASC):
      #     nullable = :nulls_first
      #
      #     # Nulls are showing up at the bottom (for example: ORDER BY column DESC):
      #     nullable = :nulls_last
      #
      # **order_direction**
      #
      # :asc or :desc
      #
      # Note: this is an optional attribute, the value will be inferred from the order_expression.
      # Sometimes it's not possible to infer the order automatically. In this case an exception will be
      # raised (when the query is executed). If the reverse order cannot be computed, it must be provided explicitly.
      #
      # **reversed_order_expression**
      #
      # The reversed version of the order_expression.
      #
      # A ColumnOrderDefinition object is able to reverse itself which is used when paginating backwards.
      # When a complex order_expression is provided (raw string), then reversing the order automatically
      # is not possible. In this case an exception will be raised.
      #
      # Example:
      #
      #   order_expression = Project.arel_table[:id].asc
      #   reversed_order_expression = Project.arel_table[:id].desc
      #
      # **add_to_projections**
      #
      # Set to true if the column is not part of the queried table. (Not part of SELECT *)
      #
      #  Example:
      #
      #  - When the order is a calculated expression or the column is in another table (JOIN-ed)
      #
      #  If the add_to_projections is true, the query builder will automatically add the column to the SELECT values
      class ColumnOrderDefinition
        REVERSED_ORDER_DIRECTIONS = { asc: :desc, desc: :asc }.freeze
        REVERSED_NULL_POSITIONS = { nulls_first: :nulls_last, nulls_last: :nulls_first }.freeze
        AREL_ORDER_CLASSES = { Arel::Nodes::Ascending => :asc, Arel::Nodes::Descending => :desc }.freeze
        ALLOWED_NULLABLE_VALUES = [:not_nullable, :nulls_first, :nulls_last].freeze

        attr_reader :attribute_name, :column_expression, :order_expression, :add_to_projections, :order_direction

        def initialize(attribute_name:, order_expression:, column_expression: nil, reversed_order_expression: nil, nullable: :not_nullable, distinct: true, order_direction: nil, add_to_projections: false)
          @attribute_name = attribute_name
          @order_expression = order_expression
          @column_expression = column_expression || calculate_column_expression(order_expression)
          @distinct = distinct
          @reversed_order_expression = reversed_order_expression || calculate_reversed_order(order_expression)
          @nullable = parse_nullable(nullable, distinct)
          @order_direction = parse_order_direction(order_expression, order_direction)
          @add_to_projections = add_to_projections
        end

        def reverse
          self.class.new(
            attribute_name: attribute_name,
            column_expression: column_expression,
            order_expression: reversed_order_expression,
            reversed_order_expression: order_expression,
            nullable: not_nullable? ? :not_nullable : REVERSED_NULL_POSITIONS[nullable],
            distinct: distinct,
            order_direction: REVERSED_ORDER_DIRECTIONS[order_direction]
          )
        end

        def ascending_order?
          order_direction == :asc
        end

        def descending_order?
          order_direction == :desc
        end

        def nulls_first?
          nullable == :nulls_first
        end

        def nulls_last?
          nullable == :nulls_last
        end

        def not_nullable?
          nullable == :not_nullable
        end

        def nullable?
          !not_nullable?
        end

        def distinct?
          distinct
        end

        private

        attr_reader :reversed_order_expression, :nullable, :distinct

        def calculate_reversed_order(order_expression)
          unless AREL_ORDER_CLASSES.has_key?(order_expression.class) # Arel can reverse simple orders
            raise "Couldn't determine reversed order for `#{order_expression}`, please provide the `reversed_order_expression` parameter."
          end

          order_expression.reverse
        end

        def calculate_column_expression(order_expression)
          if order_expression.respond_to?(:expr)
            order_expression.expr
          else
            raise("Couldn't calculate the column expression. Please pass an ARel node as the order_expression, not a string.")
          end
        end

        def parse_order_direction(order_expression, order_direction)
          transformed_order_direction = if order_direction.nil? && AREL_ORDER_CLASSES[order_expression.class]
                                          AREL_ORDER_CLASSES[order_expression.class]
                                        elsif order_direction.present?
                                          order_direction.to_s.downcase.to_sym
                                        end

          unless REVERSED_ORDER_DIRECTIONS.has_key?(transformed_order_direction)
            raise "Invalid or missing `order_direction` (value: #{order_direction}) was given, the allowed values are: :asc or :desc"
          end

          transformed_order_direction
        end

        def parse_nullable(nullable, distinct)
          if ALLOWED_NULLABLE_VALUES.exclude?(nullable)
            raise "Invalid `nullable` is given (value: #{nullable}), the allowed values are: #{ALLOWED_NULLABLE_VALUES.join(', ')}"
          end

          if nullable != :not_nullable && distinct
            raise 'Invalid column definition, `distinct` and `nullable` columns are not allowed at the same time'
          end

          nullable
        end
      end
    end
  end
end
