# frozen_string_literal: true

module Types
  class GroupMemberType < BaseObject
    expose_permissions Types::PermissionTypes::Group
    authorize :read_group

    implements MemberInterface

    graphql_name 'GroupMember'
    description 'Represents a Group Member'

    field :group, Types::GroupType, null: true,
          description: 'Group that a User is a member of',
          resolve: -> (obj, _args, _ctx) { Gitlab::Graphql::Loaders::BatchModelLoader.new(Group, obj.source_id).find }
  end
end
