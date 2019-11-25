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
    module Connections
      module Keyset
        class Connection < GraphQL::Relay::BaseConnection
          include Gitlab::Utils::StrongMemoize

          def cursor_from_node(node)
            encoded_json_from_ordering(node)
          end

          def sliced_nodes
            @sliced_nodes ||=
              begin
                OrderInfo.validate_ordering(ordered_nodes, order_list)

                sliced = ordered_nodes
                sliced = slice_nodes(sliced, before, :before) if before.present?
                sliced = slice_nodes(sliced, after, :after) if after.present?

                sliced
              end
          end

          def paged_nodes
            # These are the nodes that will be loaded into memory for rendering
            # So we're ok loading them into memory here as that's bound to happen
            # anyway. Having them ready means we can modify the result while
            # rendering the fields.
            @paged_nodes ||= load_paged_nodes.to_a
          end

          private

          def load_paged_nodes
            if first && last
              raise Gitlab::Graphql::Errors::ArgumentError.new("Can only provide either `first` or `last`, not both")
            end

            if last
              sliced_nodes.last(limit_value)
            else
              sliced_nodes.limit(limit_value) # rubocop: disable CodeReuse/ActiveRecord
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
            @limit_value ||= [first, last, max_page_size].compact.min
          end

          def ordered_nodes
            strong_memoize(:order_nodes) do
              unless nodes.primary_key.present?
                raise ArgumentError.new('Relation must have a primary key')
              end

              list = OrderInfo.build_order_list(nodes)

              # ensure there is a primary key ordering
              if list&.last&.attribute_name != nodes.primary_key
                nodes.order(arel_table[nodes.primary_key].desc) # rubocop: disable CodeReuse/ActiveRecord
              else
                nodes
              end
            end
          end

          def order_list
            strong_memoize(:order_list) do
              OrderInfo.build_order_list(ordered_nodes)
            end
          end

          def arel_table
            nodes.arel_table
          end

          # Storing the current order values in the cursor allows us to
          # make an intelligent decision on handling NULL values.
          # Otherwise we would either need to fetch the record first,
          # or fetch it in the SQL, significantly complicating it.
          def encoded_json_from_ordering(node)
            ordering = { 'id' => node[:id].to_s }

            order_list.each do |field|
              field_name = field.attribute_name
              ordering[field_name] = node[field_name].to_s
            end

            encode(ordering.to_json)
          end

          def ordering_from_encoded_json(cursor)
            JSON.parse(decode(cursor))
          rescue JSON::ParserError
            raise Gitlab::Graphql::Errors::ArgumentError, "Please provide a valid cursor"
          end
        end
      end
    end
  end
end
