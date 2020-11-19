# frozen_string_literal: true

module Types
  class GroupInvitationType < BaseObject
    expose_permissions Types::PermissionTypes::Group
    authorize :read_group

    implements InvitationInterface

    graphql_name 'GroupInvitation'
    description 'Represents a Group Invitation'

    field :group, Types::GroupType, null: true,
          description: 'Group that a User is invited to',
          resolve: -> (obj, _args, _ctx) { Gitlab::Graphql::Loaders::BatchModelLoader.new(Group, obj.source_id).find }
  end
end
