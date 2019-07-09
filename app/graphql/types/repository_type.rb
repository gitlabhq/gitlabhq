# frozen_string_literal: true

module Types
  class RepositoryType < BaseObject
    graphql_name 'Repository'

    authorize :download_code

    field :root_ref, GraphQL::STRING_TYPE, null: true, calls_gitaly: true
    field :empty, GraphQL::BOOLEAN_TYPE, null: false, method: :empty?, calls_gitaly: true
    field :exists, GraphQL::BOOLEAN_TYPE, null: false, method: :exists?
    field :tree, Types::Tree::TreeType, null: true, resolver: Resolvers::TreeResolver, calls_gitaly: true
  end
end
