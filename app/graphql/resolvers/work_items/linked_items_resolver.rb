# frozen_string_literal: true

module Resolvers
  module WorkItems
    class LinkedItemsResolver < BaseResolver
      prepend ::WorkItems::LookAheadPreloads

      alias_method :linked_items_widget, :object

      argument :filter, Types::WorkItems::RelatedLinkTypeEnum,
        required: false,
        description: "Filter by link type. " \
                     "Supported values: #{Types::WorkItems::RelatedLinkTypeEnum.values.keys.to_sentence}. " \
                     'Returns all types if omitted.'

      type Types::WorkItems::LinkedItemType.connection_type, null: true

      def resolve_with_lookahead(**args)
        apply_lookahead(related_work_items(args))
      end

      private

      def related_work_items(args)
        return WorkItem.none unless work_item.resource_parent.linked_work_items_feature_flag_enabled?

        offset_pagination(
          work_item.linked_work_items(authorize: false, link_type: args[:filter])
        )
      end

      def work_item
        linked_items_widget.work_item
      end
      strong_memoize_attr :work_item

      def node_selection(selection = lookahead)
        super.selection(:work_item)
      end
    end
  end
end
