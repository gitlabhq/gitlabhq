# frozen_string_literal: true

# Connection for an array of Active Record instances.
# Resolvers needs to handle cursors (before and after).
# This connection will handle (first and last).
# Supports batch loaded items.
# Expects the array to use a fixed DESC order. This is similar to
# ExternallyPaginatedArrayConnection.
module Gitlab
  module Graphql
    module Pagination
      class ActiveRecordArrayConnection < GraphQL::Pagination::ArrayConnection
        include ::Gitlab::Graphql::ConnectionCollectionMethods
        prepend ::Gitlab::Graphql::ConnectionRedaction

        delegate :<<, to: :items

        def nodes
          load_nodes

          @nodes
        end

        def next_page?
          load_nodes

          if before
            true
          elsif first
            limit_value < items.size
          else
            false
          end
        end

        def previous_page?
          load_nodes

          if after
            true
          elsif last
            limit_value < items.size
          else
            false
          end
        end

        # see https://graphql-ruby.org/pagination/custom_connections#connection-wrapper
        alias_method :has_next_page, :next_page?
        alias_method :has_previous_page, :previous_page?

        def cursor_for(item)
          # item could be a batch loaded item. Sync it to have the id.
          cursor = { 'id' => Gitlab::Graphql::Lazy.force(item).id.to_s }
          encode(cursor.to_json)
        end

        # Part of the implied interface for default objects for BatchLoader: objects must be clonable
        def dup
          self.class.new(
            items.dup,
            context: context,
            first: first,
            after: after,
            max_page_size: max_page_size,
            last: last,
            before: before
          )
        end

        private

        def limit_value
          # note: only first _or_ last can be specified, not both
          @limit_value ||= [first, last, max_page_size].compact.min
        end

        def load_nodes
          @nodes ||= begin
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
