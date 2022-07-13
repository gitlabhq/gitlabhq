# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      class HierarchyUpdateInputType < BaseInputObject
        graphql_name 'WorkItemWidgetHierarchyUpdateInput'

        argument :parent_id, ::Types::GlobalIDType[::WorkItem],
                 required: false,
                 loads: ::Types::WorkItemType,
                 description: 'Global ID of the parent work item. Use `null` to remove the association.'

        argument :children_ids, [::Types::GlobalIDType[::WorkItem]],
                 required: false,
                 description: 'Global IDs of children work items.',
                 prepare: ->(ids, _) { ids.map(&:model_id) }
      end
    end
  end
end
