# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      # Disabling widget level authorization as it might be too granular
      # and we already authorize the parent work item
      # rubocop:disable Graphql/AuthorizeTypes
      class AssigneesType < BaseObject
        graphql_name 'WorkItemWidgetAssignees'
        description 'Represents an assignees widget'

        implements ::Types::WorkItems::WidgetInterface

        field :assignees, ::Types::UserType.connection_type,
          null: true,
          method: :assignees_by_name_and_id,
          description: 'Assignees of the work item.'

        field :allows_multiple_assignees, GraphQL::Types::Boolean,
          null: true, method: :allows_multiple_assignees?,
          description: 'Indicates whether multiple assignees are allowed.',
          deprecated: {
            milestone: '16.7',
            replacement: 'workitemWidgetDefinitionAssignees.allowsMultipleAssignees',
            reason: 'Field moved to workItemType widget definition interface'
          }

        field :can_invite_members, GraphQL::Types::Boolean,
          null: false, resolver_method: :can_invite_members?,
          description: 'Indicates whether the current user can invite members to the work item\'s project.',
          deprecated: {
            milestone: '16.7',
            replacement: 'workitemWidgetDefinitionAssignees.canInviteMembers',
            reason: 'Field moved to workItemType widget definition interface'
          }

        def can_invite_members?
          Ability.allowed?(current_user, :admin_project_member, object.work_item.project)
        end
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
end
