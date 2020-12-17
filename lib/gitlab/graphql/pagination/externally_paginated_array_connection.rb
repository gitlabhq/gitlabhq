# frozen_string_literal: true

# Make a customized connection type
module Gitlab
  module Graphql
    module Pagination
      class ExternallyPaginatedArrayConnection < GraphQL::Pagination::ArrayConnection
        include ::Gitlab::Graphql::ConnectionCollectionMethods
        prepend ::Gitlab::Graphql::ConnectionRedaction

        delegate :start_cursor, :end_cursor, to: :items

        def next_page?
          end_cursor.present?
        end

        def previous_page?
          start_cursor.present?
        end

        alias_method :has_next_page, :next_page?
        alias_method :has_previous_page, :previous_page?

        private

        def load_nodes
          @nodes ||= begin
            # As the pagination happens externally we just grab all the nodes
            limited_nodes = items

            limited_nodes = limited_nodes.first(first) if first
            limited_nodes = limited_nodes.last(last) if last

            limited_nodes
          end
        end
      end
    end
  end
end
