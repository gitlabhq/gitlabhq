# frozen_string_literal: true

module Mutations
  module WorkItems
    module LinkedItems
      class Remove < Base
        graphql_name 'WorkItemRemoveLinkedItems'
        description 'Remove items linked to the work item.'

        argument :work_items_ids, [::Types::GlobalIDType[::WorkItem]],
          required: true,
          description: "Global IDs of the items to unlink. Maximum number of IDs you can provide: #{MAX_WORK_ITEMS}."

        private

        def update_links(work_item, params)
          gids = params.delete(:work_items_ids)
          raise Gitlab::Graphql::Errors::ArgumentError, "workItemsIds cannot be empty" if gids.empty?

          work_item_ids = gids.filter_map { |gid| gid.model_id.to_i }
          ::WorkItems::RelatedWorkItemLinks::DestroyService
            .new(work_item, current_user, { item_ids: work_item_ids })
            .execute
        end
      end
    end
  end
end
