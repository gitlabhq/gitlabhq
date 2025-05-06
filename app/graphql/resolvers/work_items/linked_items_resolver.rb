# frozen_string_literal: true

module Resolvers
  module WorkItems
    class LinkedItemsResolver < BaseResolver
      prepend ::WorkItems::LookAheadPreloads

      argument :filter, ::Types::WorkItems::RelatedLinkTypeEnum,
        required: false,
        description: "Filter by link type. " \
          "Supported values: #{Types::WorkItems::RelatedLinkTypeEnum.values.keys.to_sentence}. " \
          'Returns all types if omitted.'

      type ::Types::WorkItems::LinkedItemType.connection_type, null: true

      def resolve_with_lookahead(**args)
        if Feature.enabled?(:batch_load_linked_items, work_item.resource_parent, type: :wip)
          bulk_load_linked_items(args[:filter])
        else
          offset_pagination(
            work_item.linked_work_items(authorize: false, link_type: args[:filter])
          )
        end
      end

      private

      def work_item
        object.is_a?(Issue) ? WorkItem.find_by_id(object.id) : object.work_item
      end
      strong_memoize_attr :work_item

      def node_selection(selection = lookahead)
        super.selection(:work_item)
      end

      def bulk_load_linked_items(link_type)
        # Calculate the current nesting level of linked items in the context path
        nesting_level = context[:current_path].count('linkedItems')
        batch_key = "linked_items_level_#{nesting_level}"

        BatchLoader::GraphQL.for(work_item.id).batch(key: batch_key, cache: false) do |item_ids, loader, _args|
          preloads = [:author, :work_item_type, { project: [:route, { namespace: :route }] }]
          linked_items = apply_lookahead(WorkItem.linked_items_for(item_ids, preload: preloads, link_type: link_type))
          grouped_by_source = linked_items_grouped_by_source(linked_items, item_ids)

          # Assign the grouped items to each work item ID in the batch loader
          item_ids.each do |id|
            loader.call(id, grouped_by_source[id] || [])
          end
        end
      end

      def linked_items_grouped_by_source(linked_items, item_ids)
        linked_items.each_with_object({}) do |item, result|
          # Find the ID of the item that this item links to
          target_id = [item.issue_link_source_id, item.issue_link_target_id].find { |id| id != item.id }
          next unless item_ids.include?(target_id)

          result[target_id] ||= []
          result[target_id] << item
        end
      end
    end
  end
end
