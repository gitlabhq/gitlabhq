# frozen_string_literal: true

module Gitlab
  module Graphql
    module Pagination
      # FilterableArrayConnection is useful especially for lazy-loaded values.
      # It allows us to call a callback only on the slice of array being
      # rendered in the "after loaded" phase.  For example we can check
      # permissions only on a small subset of items.
      class FilterableArrayConnection < GraphQL::Pagination::ArrayConnection
        def nodes
          @nodes ||= items.filter_callback.call(super)
        end
      end
    end
  end
end
