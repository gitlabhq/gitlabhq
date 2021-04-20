# frozen_string_literal: true

module Resolvers
  class RepositoryBranchNamesResolver < BaseResolver
    type ::GraphQL::STRING_TYPE, null: false

    calls_gitaly!

    argument :search_pattern, GraphQL::STRING_TYPE,
      required: true,
      description: 'The pattern to search for branch names by.'

    def resolve(search_pattern:)
      Repositories::BranchNamesFinder.new(object, search: search_pattern).execute
    end
  end
end
