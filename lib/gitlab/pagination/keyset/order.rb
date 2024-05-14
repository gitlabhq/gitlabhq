# frozen_string_literal: true

module Gitlab
  module Pagination
    module Keyset
      # This class is a special ORDER BY clause which is compatible with ActiveRecord. It helps
      # building keyset paginated queries.
      #
      # In ActiveRecord we use the `order()` method which will generate the `ORDER BY X` SQL clause
      #
      # Project.where(active: true).order(id: :asc)
      #
      # # Or
      #
      # Project.where(active: true).order(created_at: :asc, id: desc)
      #
      # Gitlab::Pagination::Keyset::Order class encapsulates more information about the order columns
      # in order to implement keyset pagination in a generic way
      #
      # - Extract values from a record (usually the last item of the previous query)
      # - Build query conditions based on the column configuration
      #
      # Example 1: Order by primary key
      #
      #   # Simple order definition for the primary key as an ActiveRecord scope
      #   scope :id_asc_ordered, -> {
      #     keyset_order = Gitlab::Pagination::Keyset::Order.build([
      #       Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
      #         attribute: :id,
      #         order_expression: Project.arel_table[:id].asc
      #       )
      #     ])
      #
      #     reorder(keyset_order)
      #   }
      #
      #   # ... Later in the application code:
      #
      #   # Compatible with ActiveRecord's `order()` method
      #   page1 = Project.where(active: true).id_asc_ordered.limit(5)
      #   keyset_order = Gitlab::Pagination::Keyset::Order.extract_keyset_order_object(page1)
      #
      #   last_record = page1.last
      #   cursor_values = keyset_order.cursor_attributes_for_node(last_record) # { id: x }
      #
      #   page2 = keyset_order.apply_cursor_conditions(Project.where(active: true).id_asc_ordered, cursor_values).limit(5)
      #
      #   last_record = page2.last
      #   cursor_values = keyset_order.cursor_attributes_for_node(last_record)
      #
      #   page3 = keyset_order.apply_cursor_conditions(Project.where(active: true).id_asc_ordered, cursor_values).limit(5)
      #
      # Example 2: Order by creation time and primary key (primary key is the tie breaker)
      #
      #   scope :created_at_ordered, -> {
      #     keyset_order = Gitlab::Pagination::Keyset::Order.build([
      #       Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
      #         attribute_name: :created_at,
      #         column_expression: Project.arel_table[:created_at],
      #         order_expression: Project.arel_table[:created_at].asc,
      #         nullable: :nulls_last # we might see NULL values (bottom)
      #       ),
      #       Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
      #         attribute_name: :id,
      #         order_expression: Project.arel_table[:id].asc
      #       )
      #     ])
      #
      #     reorder(keyset_order)
      #   }
      #
      class Order < Arel::Nodes::SqlLiteral
        attr_reader :column_definitions

        def initialize(column_definitions:)
          @column_definitions = column_definitions

          super(to_sql_literal(@column_definitions))
        end

        # Tells whether the given ActiveRecord::Relation has keyset ordering
        def self.keyset_aware?(scope)
          scope.order_values.first.is_a?(self) && scope.order_values.one?
        end

        def self.extract_keyset_order_object(scope)
          scope.order_values.first
        end

        def self.build(column_definitions)
          new(column_definitions: column_definitions)
        end

        def cursor_attributes_for_node(node)
          column_definitions.each_with_object({}.with_indifferent_access) do |column_definition, hash|
            field_value = node[column_definition.attribute_name]
            hash[column_definition.attribute_name] = if field_value.is_a?(Time)
                                                       # use :inspect formatter to provide specific timezone info
                                                       # eg 2022-07-05 21:57:56.041499000 +0800
                                                       field_value.to_fs(:inspect)
                                                     elsif field_value.nil?
                                                       nil
                                                     elsif lower_named_function?(column_definition)
                                                       field_value.downcase
                                                     elsif field_value.is_a?(Array)
                                                       field_value
                                                     else
                                                       field_value.to_s
                                                     end
          end
        end

        def attribute_names
          column_definitions.map(&:attribute_name)
        end

        # This methods builds the conditions for the keyset pagination
        #
        # Example:
        #
        # |created_at|id|
        # |----------|--|
        # |2020-01-01| 1|
        # |      null| 2|
        # |      null| 3|
        # |2020-02-01| 4|
        #
        # Note: created_at is not distinct and nullable
        # Order `ORDER BY created_at DESC, id DESC`
        #
        # We get the following cursor values from the previous page:
        # { id: 4, created_at: '2020-02-01' }
        #
        # To get the next rows, we need to build the following conditions:
        #
        # (created_at = '2020-02-01' AND id < 4) OR (created_at < '2020-01-01')
        #
        # DESC ordering ensures that NULL values are on top so we don't need conditions for NULL values
        #
        # Another cursor example:
        # { id: 3, created_at: nil }
        #
        # To get the next rows, we need to build the following conditions:
        #
        # (id < 3 AND created_at IS NULL) OR (created_at IS NOT NULL)
        def build_where_values(values)
          return [] if values.blank?

          verify_incoming_values!(values)

          return use_composite_row_comparison(values) if composite_row_comparison_possible?

          column_definitions
            .map { ColumnConditionBuilder.new(_1, values[_1.attribute_name]) }
            .reverse
            .reduce([]) { |where_conditions, column| column.where_conditions(where_conditions) }
        end

        def where_values_with_or_query(values)
          build_or_query(build_where_values(values.with_indifferent_access))
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def apply_cursor_conditions(scope, values = {}, options = { use_union_optimization: false, in_operator_optimization_options: nil })
          values ||= {}
          transformed_values = values.with_indifferent_access
          scope = apply_custom_projections(scope)

          where_values = build_where_values(transformed_values)

          if options[:use_union_optimization] && where_values.size > 1
            build_union_query(scope, where_values).reorder(self)
          elsif options[:in_operator_optimization_options]
            opts = options[:in_operator_optimization_options]

            Gitlab::Pagination::Keyset::InOperatorOptimization::QueryBuilder.new(
              **{
                scope: scope.reorder(self),
                values: values
              }.merge(opts)
            ).execute
          else
            scope.where(build_or_query(where_values)) # rubocop: disable CodeReuse/ActiveRecord
          end
        end
        # rubocop: enable CodeReuse/ActiveRecord

        def reversed_order
          self.class.build(column_definitions.map(&:reverse))
        end

        alias_method :to_sql, :to_s

        private

        def lower_named_function?(column_definition)
          column_definition.column_expression.is_a?(Arel::Nodes::NamedFunction) && column_definition.column_expression.name&.downcase == 'lower'
        end

        def composite_row_comparison_possible?
          !column_definitions.one? &&
            column_definitions.all?(&:not_nullable?) &&
            column_definitions.map(&:order_direction).uniq.one? # all columns uses the same order direction
        end

        # composite row comparison works with NOT NULL columns and may use only one index scan given a proper index setup
        # Example: (created_at, id) > ('2012-09-18 01:40:01+00', 15)
        def use_composite_row_comparison(values)
          columns = Arel::Nodes::Grouping.new(column_definitions.map(&:column_expression))
          values = Arel::Nodes::Grouping.new(column_definitions.map do |column_definition|
            value = values[column_definition.attribute_name]
            build_quoted(value, column_definition.column_expression)
          end)

          if column_definitions.first.ascending_order?
            [columns.gt(values)]
          else
            [columns.lt(values)]
          end
        end

        def build_quoted(value, column_expression)
          return value if value.instance_of?(Arel::Nodes::SqlLiteral)

          Arel::Nodes.build_quoted(value, column_expression)
        end

        # Adds extra columns to the SELECT clause
        def apply_custom_projections(scope)
          additional_projections = column_definitions.select(&:add_to_projections).map do |column_definition|
            # avoid mutating the original column_expression
            column_definition.column_expression.dup.as(column_definition.attribute_name).to_sql
          end

          scope = scope.reselect(*scope.arel.projections, *additional_projections) unless additional_projections.blank?
          scope
        end

        def build_or_query(expressions)
          return [] if expressions.blank?

          or_expression = expressions.reduce { |or_expression, expression| Arel::Nodes::Or.new(or_expression, expression) }
          Arel::Nodes::Grouping.new(or_expression)
        end

        def build_union_query(scope, where_values)
          scopes = where_values.map do |where_value|
            scope.dup.where(where_value).reorder(self) # rubocop: disable CodeReuse/ActiveRecord
          end

          scope.model.select(scope.select_values).from_union(scopes, remove_duplicates: false, remove_order: false)
        end

        def to_sql_literal(column_definitions)
          column_definitions.map do |column_definition|
            if column_definition.order_expression.respond_to?(:to_sql)
              column_definition.order_expression.to_sql
            else
              column_definition.order_expression.to_s
            end
          end.join(', ')
        end

        def verify_incoming_values!(values)
          value_keys = values.keys.map(&:to_s)
          order_attrbute_names = column_definitions.map(&:attribute_name).map(&:to_s)
          missing_items = order_attrbute_names - value_keys
          extra_items = value_keys - order_attrbute_names

          if missing_items.any? || extra_items.any?
            error_text = ['Incorrect cursor values were given']

            error_text << "Extra items: #{extra_items.join(', ')}" if extra_items.any?
            error_text << "Missing items: #{missing_items.join(', ')}" if missing_items.any?

            error_text.compact

            raise error_text.join('. ')
          end
        end
      end
    end
  end
end
