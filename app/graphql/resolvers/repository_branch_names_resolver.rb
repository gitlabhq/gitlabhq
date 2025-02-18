# frozen_string_literal: true

module Resolvers
  class RepositoryBranchNamesResolver < BaseResolver
    type ::GraphQL::Types::String, null: false

    calls_gitaly!

    argument :search_pattern, GraphQL::Types::String,
      required: true,
      description: 'Pattern to search for branch names by.'

    argument :offset, GraphQL::Types::Int,
      required: true,
      description: 'Number of branch names to skip.'

    argument :limit, GraphQL::Types::Int,
      required: true,
      description: 'Number of branch names to return.'

    def resolve(search_pattern:, offset:, limit:)
      ::Repositories::BranchNamesFinder.new(object, offset: offset, limit: limit, search: search_pattern).execute
    end
  end
end
