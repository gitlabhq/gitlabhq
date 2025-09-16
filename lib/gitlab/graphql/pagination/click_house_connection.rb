# frozen_string_literal: true

module Gitlab
  module Graphql
    module Pagination
      # rubocop: disable CodeReuse/ActiveRecord -- requires AR methods to build the keyset pagination conditions
      class ClickHouseConnection < GraphQL::Pagination::Connection
        include Gitlab::Utils::StrongMemoize

        # Timestamps are stored with 6 digit microseconds precision in both PG and in CH (our schema)
        TIME_PATTERN = "%Y-%m-%d %H:%M:%S.%6N"

        # rubocop: disable Naming/PredicateName -- methods required by PageInfo
        # https://relay.dev/graphql/connections.htm#sec-undefined.PageInfo.Fields
        def has_previous_page
          if after
            # If `after` is specified, that points to a specific record,
            # even if it's the first one.  Since we're asking for `after`,
            # then the specific record we're pointing to is in the
            # previous page
            true
          elsif last
            limited_nodes
            !!@has_previous_page_cache
          else
            # Key thing to remember.  When `before` is specified (and no `last`),
            # the spec says return _all_ edges minus anything after the `before`.
            # Which means the returned list starts at the very first record.
            # Then the max_page kicks in, and returns the first max_page items.
            # Because of this, `has_previous_page` will be false
            false
          end
        end
        strong_memoize_attr :has_previous_page

        def has_next_page
          if before
            true
          elsif first
            limited_nodes.size > limit_value
          else
            false
          end
        end
        strong_memoize_attr :has_next_page

        # rubocop: enable Naming/PredicateName
        def nodes
          limited_nodes.take(limit_value)
        end

        def limited_nodes
          if last
            query = reverse_order(sliced_nodes).limit(limit_value + 1)
            nodes = execute_query(query)
            nodes = nodes.reverse unless before

            @has_previous_page_cache = nodes.count > limit_value
            @has_previous_page_cache ? nodes.last(limit_value) : nodes
          else
            # Loading LIMIT + 1 records so we can easily determine if there is next page.
            query = sliced_nodes.limit(limit_value + 1)
            nodes = execute_query(query)
            nodes = nodes.reverse if before
            nodes
          end
        end
        strong_memoize_attr :limited_nodes

        def sliced_nodes
          query = @items
          query = add_after_condition(query, after) if after
          query = add_before_condition(query, before) if before
          query
        end

        def add_after_condition(query, raw_cursor)
          order_by_columns, column_values = *build_filter_list(raw_cursor)

          grouping = Arel::Nodes::Grouping.new(order_by_columns).gt(
            Arel::Nodes::Grouping.new(column_values)
          )

          query.where(grouping)
        end

        def add_before_condition(query, raw_cursor)
          order_by_columns, column_values = *build_filter_list(raw_cursor)

          new_query = reverse_order(query)

          grouping = Arel::Nodes::Grouping.new(order_by_columns).lt(
            Arel::Nodes::Grouping.new(column_values)
          )

          new_query.where(grouping)
        end

        def limit_value
          @limit_value ||= [first, last, max_page_size || GitlabSchema.default_max_page_size].compact.min
        end

        def cursor_for(item)
          raw_cursor = orders.each_with_object({}) do |order, hash|
            expression_name = order.expr.name
            value = item[expression_name]
            raise "Cursor value for '#{expression_name}' is missing" if value.nil?

            hash[expression_name] = case
                                    when value.is_a?(Date)
                                      value.to_fs(:db)
                                    when value.is_a?(Time)
                                      # In ClickHouse we store timestamps in UTC
                                      value.utc.strftime(TIME_PATTERN)
                                    when value.is_a?(Numeric) || value.is_a?(String)
                                      value
                                    else
                                      raise 'Unsupported type in the cursor: only Time, \
                                      Numeric, and String types are supported'
                                    end
          end

          encode(Gitlab::Json.dump(raw_cursor))
        end

        def decoded_cursor(cursor)
          Gitlab::Json.parse(decode(cursor))
        rescue JSON::ParserError
          raise Gitlab::Graphql::Errors::ArgumentError, 'Invalid cursor given'
        end

        private

        def build_filter_list(raw_cursor)
          cursor = decoded_cursor(raw_cursor)

          values = []
          columns = orders.map do |order|
            expression_name = order.expr.name
            # Prevent SQL injection from a fabricated cursor value
            values << Arel.sql(::ClickHouse::Client::Quoting.quote(cursor[expression_name]))
            @items.table[expression_name]
          end

          [columns, values]
        end

        def orders
          @items.manager.ast.orders
        end

        def reverse_order(query)
          new_query = query.dup
          new_query.manager.ast.orders = orders.map do |order|
            if order.is_a?(Arel::Nodes::Ascending)
              Arel::Nodes::Descending.new(order.expr)
            else
              Arel::Nodes::Ascending.new(order.expr)
            end
          end
          new_query
        end

        def execute_query(query)
          clickhouse_connection = context[:connection] || ::ClickHouse::Connection.new(:main)
          clickhouse_connection.select(query)
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
