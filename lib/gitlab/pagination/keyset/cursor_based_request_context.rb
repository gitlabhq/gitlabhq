# frozen_string_literal: true

module Gitlab
  module Pagination
    module Keyset
      class CursorBasedRequestContext
        attr_reader :request
        delegate :params, :header, to: :request

        def initialize(request)
          @request = request
        end

        def per_page
          params[:per_page]
        end

        def cursor
          params[:cursor]
        end

        def apply_headers(cursor_for_next_page)
          Gitlab::Pagination::Keyset::HeaderBuilder
            .new(self)
            .add_next_page_header({ cursor: cursor_for_next_page })
        end
      end
    end
  end
end
