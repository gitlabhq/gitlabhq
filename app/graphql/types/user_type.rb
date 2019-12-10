# frozen_string_literal: true

module Types
  class UserType < BaseObject
    graphql_name 'User'

    authorize :read_user

    present_using UserPresenter

    expose_permissions Types::PermissionTypes::User

    field :name, GraphQL::STRING_TYPE, null: false,
          description: 'Human-readable name of the user'
    field :username, GraphQL::STRING_TYPE, null: false,
          description: 'Username of the user. Unique within this instance of GitLab'
    field :avatar_url, GraphQL::STRING_TYPE, null: false,
          description: "URL of the user's avatar"
    field :web_url, GraphQL::STRING_TYPE, null: false,
          description: 'Web URL of the user'
    field :todos, Types::TodoType.connection_type, null: false,
          resolver: Resolvers::TodoResolver,
          description: 'Todos of the user'

    field :snippets,
          Types::SnippetType.connection_type,
          null: true,
          description: 'Snippets authored by the user',
          resolver: Resolvers::Users::SnippetsResolver
  end
end
