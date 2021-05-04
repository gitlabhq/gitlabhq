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
# You can also use `Gitlab::Database.nulls_last_order`:
#
#   Issue.reorder(::Gitlab::Database.nulls_last_order('due_date', 'DESC'))
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
          prepend GenericKeysetPagination

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
                # If `before` is specified, that points to a specific record,
                # even if it's the last one.  Since we're asking for `before`,
                # then the specific record we're pointing to is in the
                # next page
                true
              elsif first
                case sliced_nodes
                when Array
                  sliced_nodes.size > limit_value
                else
                  # If we count the number of requested items plus one (`limit_value + 1`),
                  # then if we get `limit_value + 1` then we know there is a next page
                  relation_count(set_limit(sliced_nodes, limit_value + 1)) == limit_value + 1
                end
              else
                false
              end
            end
          end
          # rubocop: enable Naming/PredicateName

          def cursor_for(node)
            encoded_json_from_ordering(node)
          end

          def sliced_nodes
            @sliced_nodes ||=
              begin
                OrderInfo.validate_ordering(ordered_items, order_list) unless loaded?(ordered_items)

                sliced = ordered_items
                sliced = slice_nodes(sliced, before, :before) if before.present?
                sliced = slice_nodes(sliced, after, :after) if after.present?

                sliced
              end
          end

          def nodes
            # These are the nodes that will be loaded into memory for rendering
            # So we're ok loading them into memory here as that's bound to happen
            # anyway. Having them ready means we can modify the result while
            # rendering the fields.
            @nodes ||= limited_nodes.to_a
          end

          private

          # Apply `first` and `last` to `sliced_nodes`
          def limited_nodes
            strong_memoize(:limited_nodes) do
              if first && last
                raise Gitlab::Graphql::Errors::ArgumentError, "Can only provide either `first` or `last`, not both"
              end

              if last
                paginated_nodes = LastItems.take_items(sliced_nodes, limit_value + 1)

                # there is an extra node, so there is a previous page
                @has_previous_page = paginated_nodes.count > limit_value
                @has_previous_page ? paginated_nodes.last(limit_value) : paginated_nodes
              elsif loaded?(sliced_nodes)
                sliced_nodes.take(limit_value) # rubocop: disable CodeReuse/ActiveRecord
              else
                sliced_nodes.limit(limit_value) # rubocop: disable CodeReuse/ActiveRecord
              end
            end
          end

          # rubocop: disable CodeReuse/ActiveRecord
          def slice_nodes(sliced, encoded_cursor, before_or_after)
            decoded_cursor = ordering_from_encoded_json(encoded_cursor)
            builder = QueryBuilder.new(arel_table, order_list, decoded_cursor, before_or_after)
            ordering = builder.conditions

            sliced.where(*ordering).where.not(id: decoded_cursor['id'])
          end
          # rubocop: enable CodeReuse/ActiveRecord

          def limit_value
            # note: only first _or_ last can be specified, not both
            @limit_value ||= [first, last, max_page_size].compact.min
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

              list = OrderInfo.build_order_list(items)

              if loaded?(items) && !before.present? && !after.present?
                @order_list = list.presence || [OrderInfo.new(items.primary_key)]

                # already sorted, or trivially sorted
                next items if list.present? || items.size <= 1

                pkey = items.primary_key.to_sym
                next items.sort_by { |item| item[pkey] }.reverse
              end

              # ensure there is a primary key ordering
              if list&.last&.attribute_name != items.primary_key
                items.order(arel_table[items.primary_key].desc) # rubocop: disable CodeReuse/ActiveRecord
              else
                items
              end
            end
          end

          def order_list
            strong_memoize(:order_list) do
              OrderInfo.build_order_list(ordered_items)
            end
          end

          def arel_table
            items.arel_table
          end

          # Storing the current order values in the cursor allows us to
          # make an intelligent decision on handling NULL values.
          # Otherwise we would either need to fetch the record first,
          # or fetch it in the SQL, significantly complicating it.
          def encoded_json_from_ordering(node)
            ordering = { 'id' => node[:id].to_s }

            order_list.each do |field|
              field_name = field.try(:attribute_name) || field
              field_value = node[field_name]
              ordering[field_name] = if field_value.is_a?(Time)
                                       field_value.strftime('%Y-%m-%d %H:%M:%S.%N %Z')
                                     else
                                       field_value.to_s
                                     end
            end

            encode(ordering.to_json)
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
