# frozen_string_literal: true

module Types
  class QueryType < ::Types::BaseObject
    graphql_name 'Query'

    field :project, Types::ProjectType,
          null: true,
          resolver: Resolvers::ProjectResolver,
          description: "Find a project"

    field :group, Types::GroupType,
          null: true,
          resolver: Resolvers::GroupResolver,
          description: "Find a group"

    field :current_user, Types::UserType,
          null: true,
          resolve: -> (_obj, _args, context) { context[:current_user] },
          description: "Get information about current user"

    field :namespace, Types::NamespaceType,
          null: true,
          resolver: Resolvers::NamespaceResolver,
          description: "Find a namespace"

    field :metadata, Types::MetadataType,
          null: true,
          resolver: Resolvers::MetadataResolver,
          description: 'Metadata about GitLab'

    field :snippets,
          Types::SnippetType.connection_type,
          null: true,
          resolver: Resolvers::SnippetsResolver,
          description: 'Find Snippets visible to the current user'

    field :echo, GraphQL::STRING_TYPE, null: false,
          description: 'Text to echo back',
          resolver: Resolvers::EchoResolver
  end
end
