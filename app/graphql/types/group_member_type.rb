# frozen_string_literal: true

module Types
  class GroupMemberType < BaseObject
    graphql_name 'GroupMember'
    description 'Represents a Group Membership'

    expose_permissions Types::PermissionTypes::Group
    authorize :read_group

    implements MemberInterface

    field :group, Types::GroupType, null: true,
      description: 'Group that a user is a member of.'

    field :notification_email,
      resolver: Resolvers::GroupMembers::NotificationEmailResolver,
      description: "Group notification email for user. Only available for admins."

    def group
      Gitlab::Graphql::Loaders::BatchModelLoader.new(Group, object.source_id).find
    end
  end
end
