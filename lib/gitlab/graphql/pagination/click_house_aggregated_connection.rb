# frozen_string_literal: true

module Gitlab
  module Graphql
    module Pagination
      # Limitation: Currently, this supports only one order column.
      class ClickHouseAggregatedConnection < Gitlab::Graphql::Pagination::ClickHouseConnection
        # rubocop:disable CodeReuse/ActiveRecord -- requires AR methods to build pagination conditions
        def cursor_for(item)
          encode_cursor(item)
        end

        private

        def limited_nodes
          if last
            query = reverse_order(sliced_nodes).limit(limit_value + 1)
            nodes = execute_query(query)
            nodes = nodes.reverse

            @has_previous_page_cache = nodes.count > limit_value
            @has_previous_page_cache ? nodes.last(limit_value) : nodes
          else
            super
          end
        end

        strong_memoize_attr :limited_nodes

        def sliced_nodes
          query = ensure_stable_ordering(items)

          return query unless after || before

          conditions = []
          conditions << Arel::Nodes::Grouping.new(after_conditions) if after && after_conditions.present?
          conditions << Arel::Nodes::Grouping.new(before_conditions) if before && before_conditions.present?

          conditions.present? ? query.having(conditions.reduce(:and)) : query
        end

        def ensure_stable_ordering(query)
          group_fields = extract_group_by_fields

          # Get current orders
          current_orders = query.manager.ast.orders.dup

          # Extract the primary sort field from current orders
          primary_sort_fields = current_orders.map do |order|
            expression_name(order)
          end

          # Add GROUP BY fields to ORDER BY if they're not already there
          group_fields.each do |field|
            # Skip if this field is already in the ORDER BY
            next if primary_sort_fields.include?(field)

            current_orders << Arel::Nodes::Ascending.new(
              Arel::Nodes::SqlLiteral.new(field)
            )
          end

          query.tap do |q|
            q.manager.ast.orders = current_orders
          end
        end

        def after_conditions
          decoded = decoded_cursor(after)
          build_cursor_conditions(decoded, direction: :after)
        end
        strong_memoize_attr :after_conditions

        def before_conditions
          decoded = decoded_cursor(before)
          build_cursor_conditions(decoded, direction: :before)
        end
        strong_memoize_attr :before_conditions

        # currently this method supports only one order
        def build_cursor_conditions(cursor_data, direction:)
          sort_field, sort_order = extract_sort_info.values_at(:field, :order)
          return [] if sort_field != cursor_data['sort_field']

          sort_value = cursor_data['sort_value']

          sort_attr = Arel::Nodes::SqlLiteral.new(sort_field)

          # Start with the primary sort condition
          or_conditions = [build_primary_sort_condition(sort_attr, sort_value, sort_order, direction)]

          # Add tie-breaking conditions for group fields
          group_field_conditions = build_group_field_conditions(
            cursor_data, direction, sort_attr, sort_value, sort_field
          )

          or_conditions.concat(group_field_conditions)

          # Build nested OR conditions for stable ordering
          or_conditions.reduce do |accumulated, condition|
            Arel::Nodes::Or.new([accumulated, condition])
          end
        end

        def build_primary_sort_condition(sort_attr, sort_value, sort_order, direction)
          if direction == :after
            sort_order == :desc ? sort_attr.lt(sort_value) : sort_attr.gt(sort_value)
          else
            sort_order == :desc ? sort_attr.gt(sort_value) : sort_attr.lt(sort_value)
          end
        end

        def build_group_field_conditions(cursor_data, direction, sort_attr, sort_value, sort_field)
          group_fields = extract_group_by_fields
          conditions = []

          group_fields.each_with_index do |field, index|
            field_value = cursor_data['group_by_values'][field]
            next if field_value.nil? || field == sort_field.to_s

            and_conditions = [sort_attr.eq(sort_value)]

            # Add equality conditions for previous fields
            add_previous_field_conditions(and_conditions, group_fields, index, cursor_data, sort_field)

            # Add inequality condition for current field
            field_attr = items.table[field]
            comparison = direction == :after ? field_attr.gt(field_value) : field_attr.lt(field_value)
            and_conditions << comparison

            conditions << and_conditions.reduce(:and)
          end

          conditions
        end

        def add_previous_field_conditions(and_conditions, group_fields, current_index, cursor_data, sort_field)
          group_fields.first(current_index).each do |prev_field|
            prev_value = cursor_data['group_by_values'][prev_field.to_s]
            next if prev_value.nil? || prev_field.to_s == sort_field.to_s

            field_attr = items.table[prev_field]
            and_conditions << field_attr.eq(prev_value)
          end
        end

        def encode_cursor(node)
          sort_field = extract_sort_info[:field]
          group_fields = extract_group_by_fields

          cursor_data = {
            'sort_field' => sort_field,
            'sort_value' => node[sort_field],
            'group_by_values' => {}
          }

          # Include all GROUP BY field values
          group_fields.each do |field|
            # Exclude the sort field
            next if field == sort_field

            cursor_data['group_by_values'][field] = node[field]
          end

          encode(Gitlab::Json.dump(cursor_data))
        end

        def extract_sort_info
          orders = items.manager.ast.orders

          field = expression_name(orders.first)

          order = orders.first.is_a?(Arel::Nodes::Descending) ? :desc : :asc

          { field: field, order: order }
        end
        strong_memoize_attr :extract_sort_info

        def extract_group_by_fields
          groups = items.manager.ast.cores.first.groups
          return [] unless groups.present?

          groups.map { |attr| expression_name(attr) }
        end
        strong_memoize_attr :extract_group_by_fields

        def expression_name(attr)
          attr.expr.respond_to?(:name) ? attr.expr.name.to_s : attr.expr.to_s
        end

        def execute_query(query)
          super.map(&:with_indifferent_access)
        end
      end
      # rubocop:enable CodeReuse/ActiveRecord
    end
  end
end
