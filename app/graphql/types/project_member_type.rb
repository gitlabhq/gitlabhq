# frozen_string_literal: true

module Types
  class ProjectMemberType < BaseObject
    graphql_name 'ProjectMember'
    description 'Member of a project'

    authorize :read_project

    field :id, GraphQL::ID_TYPE, null: false,
          description: 'ID of the member'

    field :access_level, GraphQL::INT_TYPE, null: false,
          description: 'Access level of the member'

    field :user, Types::UserType, null: false,
          description: 'User that is associated with the member object',
          resolve: -> (obj, _args, _ctx) { Gitlab::Graphql::Loaders::BatchModelLoader.new(User, obj.user_id).find }
  end
end
