# frozen_string_literal: true

module Gitlab
  module Pagination
    module Keyset
      class RequestContext
        attr_reader :request

        DEFAULT_SORT_DIRECTION = :desc
        PRIMARY_KEY = :id

        # A tie breaker is added as an additional order-by column
        # to establish a well-defined order. We use the primary key
        # column here.
        TIE_BREAKER = { PRIMARY_KEY => DEFAULT_SORT_DIRECTION }.freeze

        def initialize(request)
          @request = request
        end

        # extracts Paging information from request parameters
        def page
          @page ||= Page.new(order_by: order_by, per_page: params[:per_page])
        end

        def apply_headers(next_page)
          Gitlab::Pagination::Keyset::HeaderBuilder
            .new(request)
            .add_next_page_header(
              query_params_for(next_page)
            )
        end

        private

        def order_by
          return TIE_BREAKER.dup unless params[:order_by]

          order_by = { params[:order_by].to_sym => params[:sort]&.to_sym || DEFAULT_SORT_DIRECTION }

          # Order by an additional unique key, we use the primary key here
          order_by = order_by.merge(TIE_BREAKER) unless order_by[PRIMARY_KEY]

          order_by
        end

        def params
          @params ||= request.params
        end

        def lower_bounds_params(page)
          page.lower_bounds.each_with_object({}) do |(column, value), params|
            filter = filter_with_comparator(page, column)
            params[filter] = value
          end
        end

        def filter_with_comparator(page, column)
          direction = page.order_by[column]

          if direction&.to_sym == :desc
            "#{column}_before"
          else
            "#{column}_after"
          end
        end

        def query_params_for(page)
          lower_bounds_params(page)
        end
      end
    end
  end
end
