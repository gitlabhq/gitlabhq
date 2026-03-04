# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      class HierarchyCreateInputType < BaseInputObject
        graphql_name 'WorkItemWidgetHierarchyCreateInput'

        argument :parent_id, ::Types::GlobalIDType[::WorkItem], # rubocop:disable Graphql/ForbiddenLoadsArgument -- pre-existing code; removing `loads:` would be a breaking change
          required: false,
          loads: ::Types::WorkItemType,
          description: 'Global ID of the parent work item.'
      end
    end
  end
end
