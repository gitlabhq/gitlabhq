# frozen_string_literal: true

module Types
  module WorkItems
    module WidgetDefinitions
      # rubocop:disable Graphql/AuthorizeTypes -- Authorization too granular, parent type is authorized
      class AssigneesType < BaseObject
        graphql_name 'WorkItemWidgetDefinitionAssignees'
        description 'Represents an assignees widget definition'

        implements ::Types::WorkItems::WidgetDefinitionInterface

        field :can_invite_members, GraphQL::Types::Boolean,
          null: false,
          description: 'Indicates whether the current user can invite members to the work item\'s parent.'

        def can_invite_members
          object.widget_class.can_invite_members?(current_user, resource_parent)
        end

        private

        def resource_parent
          context[:resource_parent]
        end
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
end

Types::WorkItems::WidgetDefinitions::AssigneesType.prepend_mod
