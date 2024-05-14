# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      class HierarchyCreateInputType < BaseInputObject
        graphql_name 'WorkItemWidgetHierarchyCreateInput'

        argument :parent_id, ::Types::GlobalIDType[::WorkItem],
          required: false,
          loads: ::Types::WorkItemType,
          description: 'Global ID of the parent work item.'
      end
    end
  end
end
