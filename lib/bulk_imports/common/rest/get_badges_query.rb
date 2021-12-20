# frozen_string_literal: true

module BulkImports
  module Common
    module Rest
      module GetBadgesQuery
        extend self

        def to_h(context)
          resource = context.entity.pluralized_name
          encoded_full_path = ERB::Util.url_encode(context.entity.source_full_path)

          {
            resource: [resource, encoded_full_path, 'badges'].join('/'),
            query: {
              page: context.tracker.next_page
            }
          }
        end
      end
    end
  end
end
