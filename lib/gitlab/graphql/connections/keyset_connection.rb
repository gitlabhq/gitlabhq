# frozen_string_literal: true

module Gitlab
  module Graphql
    module Connections
      class KeysetConnection < GraphQL::Relay::BaseConnection
        def cursor_from_node(node)
          encode(node[order_field].to_s)
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def sliced_nodes
          @sliced_nodes ||=
            begin
              sliced = nodes

              sliced = sliced.where(before_slice) if before.present?
              sliced = sliced.where(after_slice) if after.present?

              sliced
            end
        end
        # rubocop: enable CodeReuse/ActiveRecord

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

        def before_slice
          if sort_direction == :asc
            table[order_field].lt(decode(before))
          else
            table[order_field].gt(decode(before))
          end
        end

        def after_slice
          if sort_direction == :asc
            table[order_field].gt(decode(after))
          else
            table[order_field].lt(decode(after))
          end
        end

        def limit_value
          @limit_value ||= [first, last, max_page_size].compact.min
        end

        def table
          nodes.arel_table
        end

        def order_info
          @order_info ||= nodes.order_values.first
        end

        def order_field
          @order_field ||= order_info&.expr&.name || nodes.primary_key
        end

        def sort_direction
          @order_direction ||= order_info&.direction || :desc
        end
      end
    end
  end
end
