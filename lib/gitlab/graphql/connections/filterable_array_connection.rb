# frozen_string_literal: true

module Gitlab
  module Graphql
    module Connections
      # FilterableArrayConnection is useful especially for lazy-loaded values.
      # It allows us to call a callback only on the slice of array being
      # rendered in the "after loaded" phase.  For example we can check
      # permissions only on a small subset of items.
      class FilterableArrayConnection < GraphQL::Relay::ArrayConnection
        def paged_nodes
          @filtered_nodes ||= nodes.filter_callback.call(super)
        end
      end
    end
  end
end
