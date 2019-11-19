# frozen_string_literal: true

module Types
  class RepositoryType < BaseObject
    graphql_name 'Repository'

    authorize :download_code

    field :root_ref, GraphQL::STRING_TYPE, null: true, calls_gitaly: true,
          description: 'Default branch of the repository'
    field :empty, GraphQL::BOOLEAN_TYPE, null: false, method: :empty?, calls_gitaly: true,
          description: 'Indicates repository has no visible content'
    field :exists, GraphQL::BOOLEAN_TYPE, null: false, method: :exists?,
          description: 'Indicates a corresponding Git repository exists on disk'
    field :tree, Types::Tree::TreeType, null: true, resolver: Resolvers::TreeResolver, calls_gitaly: true,
          description: 'Tree of the repository'
  end
end
