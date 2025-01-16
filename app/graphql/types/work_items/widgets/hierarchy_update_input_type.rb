# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      class HierarchyUpdateInputType < BaseInputObject
        graphql_name 'WorkItemWidgetHierarchyUpdateInput'

        argument :adjacent_work_item_id,
          ::Types::GlobalIDType[::WorkItem],
          required: false,
          loads: ::Types::WorkItemType,
          description: 'ID of the work item to be switched with.'

        argument :children_ids, [::Types::GlobalIDType[::WorkItem]],
          required: false,
          description: 'Global IDs of children work items.',
          loads: ::Types::WorkItemType,
          as: :children

        argument :parent_id, ::Types::GlobalIDType[::WorkItem],
          required: false,
          loads: ::Types::WorkItemType,
          description: 'Global ID of the parent work item. Use `null` to remove the association.'

        argument :relative_position,
          ::Types::RelativePositionTypeEnum,
          required: false,
          description: 'Type of switch. Valid values are `BEFORE` or `AFTER`.'
      end
    end
  end
end
