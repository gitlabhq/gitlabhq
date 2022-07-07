# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      class HierarchyUpdateInputType < BaseInputObject
        graphql_name 'WorkItemWidgetHierarchyUpdateInput'

        argument :parent_id, ::Types::GlobalIDType[::WorkItem],
                 required: false,
                 description: 'Global ID of the parent work item.',
                 prepare: ->(id, _) { id&.model_id }

        argument :children_ids, [::Types::GlobalIDType[::WorkItem]],
                 required: false,
                 description: 'Global IDs of children work items.',
                 prepare: ->(ids, _) { ids.map(&:model_id) }
      end
    end
  end
end
