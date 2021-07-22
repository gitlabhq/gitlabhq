# frozen_string_literal: true

module Resolvers
  class RepositoryBranchNamesResolver < BaseResolver
    type ::GraphQL::Types::String, null: false

    calls_gitaly!

    argument :search_pattern, GraphQL::Types::String,
      required: true,
      description: 'The pattern to search for branch names by.'

    argument :offset, GraphQL::Types::Int,
      required: true,
      description: 'The number of branch names to skip.'

    argument :limit, GraphQL::Types::Int,
      required: true,
      description: 'The number of branch names to return.'

    def resolve(search_pattern:, offset:, limit:)
      Repositories::BranchNamesFinder.new(object, offset: offset, limit: limit, search: search_pattern).execute
    end
  end
end
