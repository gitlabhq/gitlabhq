# frozen_string_literal: true

module Types
  module WorkItems
    module WidgetDefinitions
      # rubocop:disable Graphql/AuthorizeTypes -- authorized in work item type entity
      class HierarchyType < BaseObject
        graphql_name 'WorkItemWidgetDefinitionHierarchy'
        description 'Represents a hierarchy widget definition'

        implements Types::WorkItems::WidgetDefinitionInterface

        field :allowed_child_types, Types::WorkItems::TypeType.connection_type,
          null: true,
          complexity: 5,
          extras: [:parent],
          description: 'Allowed child types for the work item type.'

        def allowed_child_types(parent:)
          parent.allowed_child_types(cache: true)
        end
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
end
