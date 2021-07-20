# frozen_string_literal: true

module Gitlab
  module Graphql
    module Pagination
      module Keyset
        # https://gitlab.com/gitlab-org/gitlab/-/issues/334973
        # Use the generic keyset implementation if the given ActiveRecord scope supports it.
        # Note: this module is temporary, at some point it will be merged with Keyset::Connection
        module GenericKeysetPagination
          extend ActiveSupport::Concern

          # rubocop: disable Naming/PredicateName
          # rubocop: disable CodeReuse/ActiveRecord
          def has_next_page
            return super unless Gitlab::Pagination::Keyset::Order.keyset_aware?(items)

            strong_memoize(:generic_keyset_pagination_has_next_page) do
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
                  sliced_nodes.limit(1).offset(limit_value).exists?
                  # replacing relation count
                  # relation_count(set_limit(sliced_nodes, limit_value + 1)) == limit_value + 1
                end
              else
                false
              end
            end
          end

          # rubocop: enable CodeReuse/ActiveRecord
          def ordered_items
            raise ArgumentError, 'Relation must have a primary key' unless items.primary_key.present?

            return super unless Gitlab::Pagination::Keyset::Order.keyset_aware?(items)

            items
          end

          def cursor_for(node)
            return super unless Gitlab::Pagination::Keyset::Order.keyset_aware?(items)

            order = Gitlab::Pagination::Keyset::Order.extract_keyset_order_object(items)
            encode(order.cursor_attributes_for_node(node).to_json)
          end

          def slice_nodes(sliced, encoded_cursor, before_or_after)
            return super unless Gitlab::Pagination::Keyset::Order.keyset_aware?(sliced)

            order = Gitlab::Pagination::Keyset::Order.extract_keyset_order_object(sliced)
            order = order.reversed_order if before_or_after == :before

            decoded_cursor = ordering_from_encoded_json(encoded_cursor)
            order.apply_cursor_conditions(sliced, decoded_cursor)
          end

          def sliced_nodes
            return super unless Gitlab::Pagination::Keyset::Order.keyset_aware?(items)

            sliced = ordered_items
            sliced = slice_nodes(sliced, before, :before) if before.present?
            sliced = slice_nodes(sliced, after, :after) if after.present?
            sliced
          end

          def items
            original_items = super
            return original_items if Gitlab::Pagination::Keyset::Order.keyset_aware?(original_items) || Feature.disabled?(:new_graphql_keyset_pagination)

            strong_memoize(:generic_keyset_pagination_items) do
              rebuilt_items_with_keyset_order, success = Gitlab::Pagination::Keyset::SimpleOrderBuilder.build(original_items)

              success ? rebuilt_items_with_keyset_order : original_items
            end
          end
        end
      end
    end
  end
end
