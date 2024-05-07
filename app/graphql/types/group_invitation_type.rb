# frozen_string_literal: true

module Types
  class GroupInvitationType < BaseObject
    graphql_name 'GroupInvitation'
    description 'Represents a Group Invitation'

    expose_permissions Types::PermissionTypes::Group
    authorize :admin_group

    implements InvitationInterface

    field :group, Types::GroupType, null: true,
      description: 'Group that a User is invited to.'

    def group
      Gitlab::Graphql::Loaders::BatchModelLoader.new(Group, object.source_id).find
    end
  end
end
