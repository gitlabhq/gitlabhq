# frozen_string_literal: true

module Gitlab
  module Pagination
    # Wraps existing keyset pagination for GraphQL-style pagination
    # Supports first/last with after/before cursors
    module GraphqlKeysetPagination
      extend ActiveSupport::Concern

      private

      def paginate_with_keyset(scope, pagination_params = params)
        keyset_scope, success = ::Gitlab::Pagination::Keyset::SimpleOrderBuilder.build(scope)
        raise ::Gitlab::Pagination::Keyset::UnsupportedScopeOrder unless success

        order = ::Gitlab::Pagination::Keyset::Order.extract_keyset_order_object(keyset_scope)
        paginated_scope = apply_graphql_cursor_conditions(keyset_scope, order, pagination_params)

        limit = pagination_params[:first] || pagination_params[:last] || default_page_limit
        records = paginated_scope.limit(limit + 1).to_a

        has_more = records.size > limit
        records = records.slice(0, limit)

        # Reverse if using 'last'
        records.reverse! if pagination_params[:last].present?

        {
          records: records,
          page_info: build_keyset_page_info(order, records, has_more, pagination_params)
        }
      end

      def apply_graphql_cursor_conditions(scope, order, pagination_params)
        after_cursor = decode_cursor(pagination_params[:after])
        before_cursor = decode_cursor(pagination_params[:before])

        if pagination_params[:last].present?
          apply_cursor_conditions_for_last(scope, order, after_cursor, before_cursor)
        else
          apply_cursor_conditions_for_first(scope, order, after_cursor, before_cursor)
        end
      end

      def apply_cursor_conditions_for_first(scope, order, after_cursor, before_cursor)
        scope = order.apply_cursor_conditions(scope, after_cursor) if after_cursor.present?

        if before_cursor.present?
          before_conditions = order.reversed_order.where_values_with_or_query(before_cursor)
          scope = scope.where(before_conditions) # rubocop: disable CodeReuse/ActiveRecord -- Should be generic
        end

        scope
      end

      def apply_cursor_conditions_for_last(scope, order, after_cursor, before_cursor)
        reversed_order = order.reversed_order

        # In reversed order, "before" acts like "after", "after" acts like "before"
        scope = reversed_order.apply_cursor_conditions(scope, before_cursor) if before_cursor.present?

        if after_cursor.present?
          after_as_before_conditions = order.where_values_with_or_query(after_cursor)
          scope = scope.where(after_as_before_conditions) # rubocop: disable CodeReuse/ActiveRecord -- Should be generic
        end

        scope.reorder(reversed_order) # rubocop: disable CodeReuse/ActiveRecord -- Should be generic
      end

      def decode_cursor(cursor)
        return {} if cursor.blank?

        ::Gitlab::Pagination::Keyset::Paginator::Base64CursorConverter.parse(cursor)
      rescue StandardError
        {}
      end

      def encode_keyset_cursor(attributes)
        ::Gitlab::Pagination::Keyset::Paginator::Base64CursorConverter.dump(attributes)
      end

      def build_keyset_page_info(order, records, has_more, pagination_params)
        return empty_keyset_page_info if records.empty?

        {
          has_next_page: calculate_has_next_page(has_more, pagination_params),
          has_previous_page: calculate_has_previous_page(has_more, pagination_params),
          start_cursor: encode_keyset_cursor(order.cursor_attributes_for_node(records.first)),
          end_cursor: encode_keyset_cursor(order.cursor_attributes_for_node(records.last))
        }
      end

      def calculate_has_next_page(has_more, pagination_params)
        return pagination_params[:before].present? if pagination_params[:last].present?

        has_more
      end

      def calculate_has_previous_page(has_more, pagination_params)
        if pagination_params[:first].present?
          pagination_params[:after].present?
        elsif pagination_params[:last].present?
          has_more
        else
          false
        end
      end

      def empty_keyset_page_info
        {
          has_next_page: false,
          has_previous_page: false,
          start_cursor: nil,
          end_cursor: nil
        }
      end

      def default_page_limit
        Kaminari.config.default_per_page
      end
    end
  end
end
