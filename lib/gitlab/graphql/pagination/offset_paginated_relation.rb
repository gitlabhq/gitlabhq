# frozen_string_literal: true

# Marker class to enable us to choose the correct
# connection type during resolution
module Gitlab
  module Graphql
    module Pagination
      class OffsetPaginatedRelation < SimpleDelegator
        def preload(...)
          if Feature.enabled?(:fix_graphql_offset_pagination_preloads, Feature.current_request)
            self.class.new(super)
          else
            super
          end
        end

        def includes(...)
          if Feature.enabled?(:fix_graphql_offset_pagination_preloads, Feature.current_request)
            self.class.new(super)
          else
            super
          end
        end
      end
    end
  end
end
