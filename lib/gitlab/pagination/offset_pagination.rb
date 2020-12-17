# frozen_string_literal: true

module Gitlab
  module Pagination
    class OffsetPagination < Base
      attr_reader :request_context
      delegate :params, :header, :request, to: :request_context

      def initialize(request_context)
        @request_context = request_context
      end

      def paginate(relation, exclude_total_headers: false)
        paginate_with_limit_optimization(add_default_order(relation)).tap do |data|
          add_pagination_headers(data, exclude_total_headers)
        end
      end

      private

      def paginate_with_limit_optimization(relation)
        # do not paginate relation if it is already paginated
        pagination_data = if relation.respond_to?(:current_page) && relation.current_page == params[:page] && relation.limit_value == params[:per_page]
                            relation
                          else
                            relation.page(params[:page]).per(params[:per_page])
                          end

        return pagination_data unless pagination_data.is_a?(ActiveRecord::Relation)
        return pagination_data unless Feature.enabled?(:api_kaminari_count_with_limit, type: :ops)

        limited_total_count = pagination_data.total_count_with_limit
        if limited_total_count > Kaminari::ActiveRecordRelationMethods::MAX_COUNT_LIMIT
          # The call to `total_count_with_limit` memoizes `@arel` because of a call to `references_eager_loaded_tables?`
          # We need to call `reset` because `without_count` relies on `@arel` being unmemoized
          pagination_data.reset.without_count
        else
          pagination_data
        end
      end

      def add_default_order(relation)
        if relation.is_a?(ActiveRecord::Relation) && relation.order_values.empty?
          relation = relation.order(:id) # rubocop: disable CodeReuse/ActiveRecord
        end

        relation
      end

      def add_pagination_headers(paginated_data, exclude_total_headers)
        Gitlab::Pagination::OffsetHeaderBuilder.new(
          request_context: self, per_page: paginated_data.limit_value, page: paginated_data.current_page,
          next_page: paginated_data.next_page, prev_page: paginated_data.prev_page,
          total: total_count(paginated_data), total_pages: total_pages(paginated_data)
        ).execute(exclude_total_headers: exclude_total_headers, data_without_counts: data_without_counts?(paginated_data))
      end

      def data_without_counts?(paginated_data)
        paginated_data.is_a?(Kaminari::PaginatableWithoutCount)
      end

      def total_count(paginated_data)
        paginated_data.total_count unless data_without_counts?(paginated_data)
      end

      def total_pages(paginated_data)
        return if data_without_counts?(paginated_data)

        # Ensure there is in total at least 1 page
        [paginated_data.total_pages, 1].max
      end
    end
  end
end
