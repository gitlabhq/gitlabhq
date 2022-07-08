# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      class HierarchyCreateInputType < BaseInputObject
        graphql_name 'WorkItemWidgetHierarchyCreateInput'

        argument :parent_id, ::Types::GlobalIDType[::WorkItem],
                 required: false,
                 description: 'Global ID of the parent work item.',
                 prepare: ->(id, _) { id&.model_id }
      end
    end
  end
end
