# frozen_string_literal: true

module Resolvers
  module WorkItems
    class LinkedItemsResolver < BaseResolver
      alias_method :linked_items_widget, :object

      argument :filter, Types::WorkItems::RelatedLinkTypeEnum,
        required: false,
        description: "Filter by link type. " \
                     "Supported values: #{Types::WorkItems::RelatedLinkTypeEnum.values.keys.to_sentence}. " \
                     'Returns all types if omitted.'

      type Types::WorkItems::LinkedItemType.connection_type, null: true

      def resolve(filter: nil)
        related_work_items(filter).map do |related_work_item|
          {
            link_id: related_work_item.issue_link_id,
            link_type: related_work_item.issue_link_type,
            link_created_at: related_work_item.issue_link_created_at,
            link_updated_at: related_work_item.issue_link_updated_at,
            work_item: related_work_item
          }
        end
      end

      private

      def related_work_items(type)
        return [] unless work_item.project.linked_work_items_feature_flag_enabled?

        work_item.linked_work_items(current_user, preload: { project: [:project_feature, :group] }, link_type: type)
      end

      def work_item
        linked_items_widget.work_item
      end
      strong_memoize_attr :work_item
    end
  end
end
