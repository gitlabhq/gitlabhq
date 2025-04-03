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
        bulk_load_linked_items(args[:filter])
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
        BatchLoader::GraphQL.for(work_item.id).batch(key: work_item.class.name, cache: false) do |ids, loader, _args|
          items_preload = [:author, :work_item_type, { project: [:route, { namespace: :route }] }]
          linked_items = apply_lookahead(WorkItem.linked_items_for(ids, preload: items_preload, link_type: link_type))
          grouped_items = linked_items_grouped_by_source(linked_items, ids)

          ids.each { |id| loader.call(id, grouped_items[id] || []) }
        end
      end

      def linked_items_grouped_by_source(linked_items, source_ids)
        linked_items.each_with_object({}) do |item, result|
          link_source_id = item.issue_link_source_id
          link_target_id = item.issue_link_target_id

          reference_id = [link_source_id, link_target_id].find { |id| source_ids.include?(id) }
          next unless reference_id

          result[reference_id] ||= []
          result[reference_id] << item
        end
      end
    end
  end
end
