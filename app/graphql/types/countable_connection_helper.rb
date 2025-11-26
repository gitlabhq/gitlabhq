# frozen_string_literal: true

# rubocop: disable Gitlab/BoundedContexts -- Not a bounded context
module Types
  module CountableConnectionHelper
    extend ActiveSupport::Concern

    # Performs a limited count on the relation
    # Returns limit + 1 when count exceeds limit, otherwise returns exact count
    def limited_count(relation, limit)
      if relation.respond_to?(:page)
        relation.page.total_count_with_limit(:all, limit: limit)
      else
        [relation.size, limit.next].min
      end
    end
  end
end
# rubocop: enable Gitlab/BoundedContexts
