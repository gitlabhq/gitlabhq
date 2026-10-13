# frozen_string_literal: true

module Gitlab
  module Graphql
    # Adds the size of each connection page to the query's `graphql_connection_nodes` log field.
    module ConnectionNodesCount
      class Counter
        def initialize
          @counted_size = 0
        end

        # `nodes` runs many times and can be recomputed, so add only the change in size.
        def count(logging, size)
          logging[:connection_nodes] = logging.fetch(:connection_nodes, 0) + size - @counted_size
          @counted_size = size
        end
      end

      def nodes
        super.tap { |nodes| nodes_counter.count(context.namespace(:gl_logging), nodes.size) }
      end

      private

      def nodes_counter
        @nodes_counter ||= Counter.new
      end
    end
  end
end
