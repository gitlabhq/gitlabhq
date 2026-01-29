# frozen_string_literal: true

module API
  module Entities
    module Glql
      class PageInfo < Grape::Entity
        expose :endCursor,
          documentation: { type: 'String', example: 'eyJpZCI6IjE3In0', desc: 'Cursor for the last item' }
        expose :hasNextPage, documentation: { type: 'Boolean', example: true, desc: 'Whether there are more items' }
        expose :hasPreviousPage,
          documentation: { type: 'Boolean', example: false, desc: 'Whether there are previous items' }
        expose :startCursor,
          documentation: { type: 'String', example: 'eyJpZCI6IjE3In0', desc: 'Cursor for the first item' }
      end
    end
  end
end
