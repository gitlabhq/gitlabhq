# frozen_string_literal: true

# Keyset::Connection provides cursor based pagination, to avoid using OFFSET.
# It basically sorts / filters using WHERE sorting_value > cursor.
# We do this for performance reasons (https://gitlab.com/gitlab-org/gitlab-foss/issues/45756),
# as well as for having stable pagination
# https://graphql-ruby.org/pro/cursors.html#whats-the-difference
# https://coderwall.com/p/lkcaag/pagination-you-re-probably-doing-it-wrong
#
# It currently supports sorting on two columns, but the last column must
# be the primary key. If it's not already included, an order on the
# primary key will be added automatically, like `order(id: :desc)`
#
#   Issue.order(created_at: :asc).order(:id)
#   Issue.order(due_date: :asc)
#
# It will tolerate non-attribute ordering, but only attributes determine the cursor.
# For example, this is legitimate:
#
#   Issue.order('issues.due_date IS NULL').order(due_date: :asc).order(:id)
#
# but anything more complex has a chance of not working.
#
module Gitlab
  module Graphql
    module Pagination
      module Keyset
        class Connection < GraphQL::Pagination::ActiveRecordRelationConnection
          include Gitlab::Utils::StrongMemoize
          include ::Gitlab::Graphql::ConnectionCollectionMethods
          prepend ::Gitlab::Graphql::ConnectionRedaction

          # rubocop: disable Naming/PredicateName
          # https://relay.dev/graphql/connections.htm#sec-undefined.PageInfo.Fields
          def has_previous_page
            strong_memoize(:has_previous_page) do
              if after
                # If `after` is specified, that points to a specific record,
                # even if it's the first one.  Since we're asking for `after`,
                # then the specific record we're pointing to is in the
                # previous page
                true
              elsif last
                limited_nodes
                !!@has_previous_page
              else
                # Key thing to remember.  When `before` is specified (and no `last`),
                # the spec says return _all_ edges minus anything after the `before`.
                # Which means the returned list starts at the very first record.
                # Then the max_page kicks in, and returns the first max_page items.
                # Because of this, `has_previous_page` will be false
                false
              end
            end
          end

          def has_next_page
            strong_memoize(:has_next_page) do
              if before
                true
              elsif first
                limited_nodes.size > limit_value
              else
                false
              end
            end
          end
          # rubocop: enable Naming/PredicateName

          def cursor_for(node)
            order = Gitlab::Pagination::Keyset::Order.extract_keyset_order_object(items)
            encode(order.cursor_attributes_for_node(node).to_json)
          end

          def sliced_nodes
            sliced = ordered_items
            sliced = slice_nodes(sliced, before, :before) if before.present?
            sliced = slice_nodes(sliced, after, :after) if after.present?
            sliced
          end

          def nodes
            # These are the nodes that will be loaded into memory for rendering
            # So we're ok loading them into memory here as that's bound to happen
            # anyway. Having them ready means we can modify the result while
            # rendering the fields.
            @nodes ||= limited_nodes.to_a.take(limit_value) # rubocop: disable CodeReuse/ActiveRecord
          end

          def items
            original_items = super
            return original_items if Gitlab::Pagination::Keyset::Order.keyset_aware?(original_items)

            strong_memoize(:keyset_pagination_items) do
              rebuilt_items_with_keyset_order, success =
                Gitlab::Pagination::Keyset::SimpleOrderBuilder.build(original_items)

              raise(Gitlab::Pagination::Keyset::UnsupportedScopeOrder) unless success

              rebuilt_items_with_keyset_order
            end
          end

          private

          # Apply `first` and `last` to `sliced_nodes`
          def limited_nodes
            strong_memoize(:limited_nodes) do
              if first && last
                raise Gitlab::Graphql::Errors::ArgumentError, "Can only provide either `first` or `last`, not both"
              end

              if last
                paginated_nodes = sliced_nodes.last(limit_value + 1)

                # there is an extra node, so there is a previous page
                @has_previous_page = paginated_nodes.count > limit_value
                @has_previous_page ? paginated_nodes.last(limit_value) : paginated_nodes
              elsif loaded?(sliced_nodes)
                sliced_nodes.take(limit_value + 1) # rubocop: disable CodeReuse/ActiveRecord
              else
                sliced_nodes.limit(limit_value + 1).to_a
              end
            end
          end

          def slice_nodes(sliced, encoded_cursor, before_or_after)
            order = Gitlab::Pagination::Keyset::Order.extract_keyset_order_object(sliced)
            order = order.reversed_order if before_or_after == :before

            decoded_cursor = ordering_from_encoded_json(encoded_cursor)
            order.apply_cursor_conditions(sliced, decoded_cursor)
          end

          def limit_value
            # note: only first _or_ last can be specified, not both
            @limit_value ||= [first, last, max_page_size || GitlabSchema.default_max_page_size].compact.min
          end

          def loaded?(items)
            case items
            when Array
              true
            else
              items.loaded?
            end
          end

          def ordered_items
            strong_memoize(:ordered_items) do
              unless items.primary_key.present?
                raise ArgumentError, 'Relation must have a primary key'
              end

              items
            end
          end

          def ordering_from_encoded_json(cursor)
            Gitlab::Json.parse(decode(cursor))
          rescue JSON::ParserError
            raise Gitlab::Graphql::Errors::ArgumentError, "Please provide a valid cursor"
          end
        end
      end
    end
  end
end
