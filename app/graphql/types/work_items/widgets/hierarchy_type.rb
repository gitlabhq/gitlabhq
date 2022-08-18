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

        field :parent, ::Types::WorkItemType,
          null: true, complexity: 5,
          description: 'Parent work item.'

        field :children, ::Types::WorkItemType.connection_type,
          null: true, complexity: 5,
          description: 'Child work items.'

        def children
          object.children.inc_relations_for_permission_check
        end
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
end
