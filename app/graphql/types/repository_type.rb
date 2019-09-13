# frozen_string_literal: true

module Types
  class RepositoryType < BaseObject
    graphql_name 'Repository'

    authorize :download_code

    field :root_ref, GraphQL::STRING_TYPE, null: true, calls_gitaly: true # rubocop:disable Graphql/Descriptions
    field :empty, GraphQL::BOOLEAN_TYPE, null: false, method: :empty?, calls_gitaly: true # rubocop:disable Graphql/Descriptions
    field :exists, GraphQL::BOOLEAN_TYPE, null: false, method: :exists? # rubocop:disable Graphql/Descriptions
    field :tree, Types::Tree::TreeType, null: true, resolver: Resolvers::TreeResolver, calls_gitaly: true # rubocop:disable Graphql/Descriptions
  end
end
