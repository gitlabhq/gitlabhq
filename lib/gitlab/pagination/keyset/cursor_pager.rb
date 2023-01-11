# frozen_string_literal: true

module Gitlab
  module Pagination
    module Keyset
      class CursorPager < Gitlab::Pagination::Base
        attr_reader :cursor_based_request_context, :paginator

        def initialize(cursor_based_request_context)
          @cursor_based_request_context = cursor_based_request_context
        end

        def paginate(relation, _params = {})
          @paginator ||= relation.keyset_paginate(
            per_page: cursor_based_request_context.per_page,
            cursor: cursor_based_request_context.cursor
          )

          paginator.records
        end

        def finalize(_records = [])
          # can be called only after executing `paginate(relation)`
          apply_headers
        end

        private

        def apply_headers
          return unless paginator.has_next_page?

          cursor_based_request_context
            .apply_headers(paginator.cursor_for_next_page)
        end
      end
    end
  end
end
