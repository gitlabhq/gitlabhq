# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      # Disabling widget level authorization as it might be too granular
      # and we already authorize the parent work item
      # rubocop:disable Graphql/AuthorizeTypes
      class HierarchyType < BaseObject
        graphql_name 'WorkItemWidgetHierarchy'
        description 'Represents a hierarchy widget'

        implements Types::WorkItems::WidgetInterface

        field :parent, ::Types::WorkItemType, null: true,
              description: 'Parent work item.',
              complexity: 5

        field :children, ::Types::WorkItemType.connection_type, null: true,
              description: 'Child work items.',
              complexity: 5

        def children
          object.children.inc_relations_for_permission_check
        end
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
end
