# frozen_string_literal: true

module BulkImports
  module Groups
    module Rest
      module GetBadgesQuery
        extend self

        def to_h(context)
          encoded_full_path = ERB::Util.url_encode(context.entity.source_full_path)

          {
            resource: ['groups', encoded_full_path, 'badges'].join('/'),
            query: {
              page: context.tracker.next_page
            }
          }
        end
      end
    end
  end
end
