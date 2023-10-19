# frozen_string_literal: true

module Mutations
  module WorkItems
    module LinkedItems
      class Add < Base
        graphql_name 'WorkItemAddLinkedItems'
        description 'Add linked items to the work item.'

        argument :link_type, ::Types::WorkItems::RelatedLinkTypeEnum,
          required: false, description: 'Type of link. Defaults to `RELATED`.'
        argument :work_items_ids, [::Types::GlobalIDType[::WorkItem]],
          required: true,
          description: "Global IDs of the items to link. Maximum number of IDs you can provide: #{MAX_WORK_ITEMS}."

        private

        def update_links(work_item, params)
          gids = params.delete(:work_items_ids)
          work_items = begin
            GitlabSchema.parse_gids(gids, expected_type: ::WorkItem).map(&:find)
          rescue ActiveRecord::RecordNotFound => e
            raise Gitlab::Graphql::Errors::ArgumentError, e
          end

          ::WorkItems::RelatedWorkItemLinks::CreateService
            .new(work_item, current_user, { target_issuable: work_items, link_type: params[:link_type] })
            .execute
        end
      end
    end
  end
end
