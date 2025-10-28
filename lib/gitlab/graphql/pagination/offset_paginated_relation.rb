# frozen_string_literal: true

# Marker class to enable us to choose the correct
# connection type during resolution
module Gitlab
  module Graphql
    module Pagination
      class OffsetPaginatedRelation < SimpleDelegator
        def preload(...)
          self.class.new(super)
        end

        def includes(...)
          self.class.new(super)
        end
      end
    end
  end
end
