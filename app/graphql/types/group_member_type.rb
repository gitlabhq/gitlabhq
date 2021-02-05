# frozen_string_literal: true

module Types
  class GroupMemberType < BaseObject
    expose_permissions Types::PermissionTypes::Group
    authorize :read_group

    implements MemberInterface

    graphql_name 'GroupMember'
    description 'Represents a Group Membership'

    field :group, Types::GroupType, null: true,
          description: 'Group that a User is a member of.'

    def group
      Gitlab::Graphql::Loaders::BatchModelLoader.new(Group, object.source_id).find
    end
  end
end
