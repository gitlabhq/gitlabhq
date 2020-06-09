# frozen_string_literal: true

module Types
  class ProjectMemberType < BaseObject
    graphql_name 'ProjectMember'
    description 'Represents a Project Member'

    expose_permissions Types::PermissionTypes::Project

    implements MemberInterface

    authorize :read_project

    field :id, GraphQL::ID_TYPE, null: false,
          description: 'ID of the member'

    field :user, Types::UserType, null: false,
          description: 'User that is associated with the member object',
          resolve: -> (obj, _args, _ctx) { Gitlab::Graphql::Loaders::BatchModelLoader.new(User, obj.user_id).find }

    field :project, Types::ProjectType, null: true,
          description: 'Project that User is a member of',
          resolve: -> (obj, _args, _ctx) { Gitlab::Graphql::Loaders::BatchModelLoader.new(Project, obj.source_id).find }
  end
end
