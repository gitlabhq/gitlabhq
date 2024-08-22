# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      class LinkedItemsCreateInputType < BaseInputObject
        graphql_name 'WorkItemWidgetLinkedItemsCreateInput'

        MAX_WORK_ITEMS = 10
        ERROR_MESSAGE = "No more than #{MAX_WORK_ITEMS} work items can be linked at the same time.".freeze

        argument :link_type, ::Types::WorkItems::RelatedLinkTypeEnum,
          required: false, description: 'Type of link. Defaults to `RELATED`.'
        argument :work_items_ids, [::Types::GlobalIDType[::WorkItem]],
          description: "Global IDs of the items to link. Maximum number of IDs you can provide: #{MAX_WORK_ITEMS}.",
          required: true,
          prepare: ->(ids, _ctx) do
            raise Gitlab::Graphql::Errors::ArgumentError, ERROR_MESSAGE if ids.size > MAX_WORK_ITEMS

            ids.map { |gid| gid.model_id.to_i }
          end
      end
    end
  end
end
