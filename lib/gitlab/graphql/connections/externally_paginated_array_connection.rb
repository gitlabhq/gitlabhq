# frozen_string_literal: true

# Make a customized connection type
module Gitlab
  module Graphql
    module Connections
      class ExternallyPaginatedArrayConnection < GraphQL::Relay::ArrayConnection
        # As the pagination happens externally
        # we just return all the nodes here.
        def sliced_nodes
          @nodes
        end

        def start_cursor
          nodes.previous_cursor
        end

        def end_cursor
          nodes.next_cursor
        end

        def next_page?
          end_cursor.present?
        end

        def previous_page?
          start_cursor.present?
        end

        alias_method :has_next_page, :next_page?
        alias_method :has_previous_page, :previous_page?
      end
    end
  end
end
