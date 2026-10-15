# frozen_string_literal: true

module API
  module Helpers
    module WorkItems
      module CursorPaginationParams
        extend Grape::API::Helpers

        # Work item collections page by opaque cursor only. Do not `use :pagination` next to this:
        # it would declare a `page` param the keyset pager ignores.
        params :work_items_cursor_pagination_params do
          optional :cursor, type: String, limit: 1024,
            desc: 'Cursor for obtaining the next set of records.', documentation: { example: 'eyJpZCI6IjE0In0' }
          optional :per_page, type: Integer, default: 20, values: 1..100,
            desc: 'Number of items to list per page (maximum 100).', documentation: { example: 20 }
        end
      end
    end
  end
end
