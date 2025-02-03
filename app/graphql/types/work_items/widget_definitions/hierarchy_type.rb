# frozen_string_literal: true

module Types
  module WorkItems
    module WidgetDefinitions
      # rubocop:disable Graphql/AuthorizeTypes -- authorized in work item type entity
      # rubocop:disable GraphQL/ExtractType -- no need to extra allowed types into a seperate field
      class HierarchyType < BaseObject
        graphql_name 'WorkItemWidgetDefinitionHierarchy'
        description 'Represents a hierarchy widget definition'

        implements ::Types::WorkItems::WidgetDefinitionInterface

        field :allowed_child_types, ::Types::WorkItems::TypeType.connection_type,
          null: true,
          complexity: 5,
          extras: [:parent],
          description: 'Allowed child types for the work item type.'

        field :allowed_parent_types, ::Types::WorkItems::TypeType.connection_type,
          null: true,
          extras: [:parent],
          complexity: 5,
          description: 'Allowed parent types for the work item type.'

        def allowed_child_types(parent:)
          parent.allowed_child_types(cache: true, authorize: true, resource_parent: context[:resource_parent])
        end

        def allowed_parent_types(parent:)
          parent.allowed_parent_types(cache: true, authorize: true, resource_parent: context[:resource_parent])
        end
      end
      # rubocop:enable Graphql/AuthorizeTypes
      # rubocop:enable GraphQL/ExtractType
    end
  end
end
