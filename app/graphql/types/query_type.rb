# frozen_string_literal: true

module Types
  class QueryType < ::Types::BaseObject
    graphql_name 'Query'

    # The design management context object needs to implement #issue
    DesignManagementObject = Struct.new(:issue)

    field :project, Types::ProjectType,
          null: true,
          resolver: Resolvers::ProjectResolver,
          description: "Find a project"

    field :projects, Types::ProjectType.connection_type,
          null: true,
          resolver: Resolvers::ProjectsResolver,
          description: "Find projects visible to the current user"

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

    field :design_management, Types::DesignManagementType,
          null: false,
          description: 'Fields related to design management'

    field :user, Types::UserType,
          null: true,
          description: 'Find a user',
          resolver: Resolvers::UserResolver

    field :users, Types::UserType.connection_type,
          null: true,
          description: 'Find users',
          resolver: Resolvers::UsersResolver

    field :echo, GraphQL::STRING_TYPE, null: false,
          description: 'Text to echo back',
          resolver: Resolvers::EchoResolver

    field :user, Types::UserType, null: true,
          description: 'Find a user on this instance',
          resolver: Resolvers::UserResolver

    def design_management
      DesignManagementObject.new(nil)
    end
  end
end

Types::QueryType.prepend_if_ee('EE::Types::QueryType')
