# frozen_string_literal: true

# TODO https://gitlab.com/gitlab-org/gitlab/issues/35104
module Gitlab
  module Graphql
    module Connections
      module Keyset
        module LegacyKeysetConnection
          def legacy_cursor_from_node(node)
            encode(node[legacy_order_field].to_s)
          end

          # rubocop: disable CodeReuse/ActiveRecord
          def legacy_sliced_nodes
            @sliced_nodes ||=
              begin
                sliced = nodes

                sliced = sliced.where(legacy_before_slice) if before.present?
                sliced = sliced.where(legacy_after_slice) if after.present?

                sliced
              end
          end
          # rubocop: enable CodeReuse/ActiveRecord

          private

          def use_legacy_pagination?
            strong_memoize(:feature_disabled) do
              Feature.disabled?(:graphql_keyset_pagination, default_enabled: true)
            end
          end

          def legacy_before_slice
            if legacy_sort_direction == :asc
              arel_table[legacy_order_field].lt(decode(before))
            else
              arel_table[legacy_order_field].gt(decode(before))
            end
          end

          def legacy_after_slice
            if legacy_sort_direction == :asc
              arel_table[legacy_order_field].gt(decode(after))
            else
              arel_table[legacy_order_field].lt(decode(after))
            end
          end

          def legacy_order_info
            @legacy_order_info ||= nodes.order_values.first
          end

          def legacy_order_field
            @legacy_order_field ||= legacy_order_info&.expr&.name || nodes.primary_key
          end

          def legacy_sort_direction
            @legacy_order_direction ||= legacy_order_info&.direction || :desc
          end
        end
      end
    end
  end
end
