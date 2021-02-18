# frozen_string_literal: true

# Marker class to enable us to choose the correct
# connection type during resolution
module Gitlab
  module Graphql
    module Pagination
      class OffsetPaginatedRelation < SimpleDelegator
      end
    end
  end
end
