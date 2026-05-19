# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  class BranchType < BaseObject
    graphql_name 'Branch'

    authorize_granular_token permissions: :read_branch,
      boundary: ->(obj) {
        container = obj.dereferenced_target&.repository&.container
        container if container.is_a?(Project)
      },
      boundary_type: :project

    field :name,
      GraphQL::Types::String,
      null: false,
      description: 'Name of the branch.'

    field :commit, Types::Repositories::CommitType,
      null: true, resolver: Resolvers::Repositories::RefCommitResolver,
      description: 'Commit for the branch.'
  end
  # rubocop: enable Graphql/AuthorizeTypes
end
