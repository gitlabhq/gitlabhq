# frozen_string_literal: true

module BulkImports
  module Common
    module Rest
      module GetBadgesQuery
        extend self

        def to_h(context)
          {
            resource: [context.entity.base_resource_path, 'badges'].join('/'),
            query: {
              page: context.tracker.next_page
            }
          }
        end
      end
    end
  end
end
