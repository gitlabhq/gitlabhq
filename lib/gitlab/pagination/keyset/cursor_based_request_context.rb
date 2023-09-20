# frozen_string_literal: true

module Gitlab
  module Pagination
    module Keyset
      class CursorBasedRequestContext
        DEFAULT_SORT_DIRECTION = :desc
        DEFAULT_SORT_COLUMN = :id

        attr_reader :request_context

        delegate :params, to: :request_context

        def initialize(request_context)
          @request_context = request_context
        end

        def per_page
          params[:per_page]
        end

        def cursor
          params[:cursor]
        end

        def apply_headers(cursor_for_next_page)
          Gitlab::Pagination::Keyset::HeaderBuilder
            .new(request_context)
            .add_next_page_header({ cursor: cursor_for_next_page })
        end

        def order_by
          { (params[:order_by]&.to_sym || DEFAULT_SORT_COLUMN) => (params[:sort]&.to_sym || DEFAULT_SORT_DIRECTION) }
        end

        def order
          params[:order_by]&.to_sym || DEFAULT_SORT_COLUMN
        end

        def sort
          params[:sort]&.to_sym || DEFAULT_SORT_DIRECTION
        end
      end
    end
  end
end
