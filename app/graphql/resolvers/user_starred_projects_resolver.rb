# frozen_string_literal: true

module Resolvers
  class UserStarredProjectsResolver < BaseResolver
    type Types::ProjectType.connection_type, null: true

    argument :search, GraphQL::Types::String,
      required: false,
      description: 'Search query.'

    argument :sort, Types::Projects::ProjectSortEnum,
      required: false,
      description: "List starred projects by sort order.",
      default_value: :name_asc

    alias_method :user, :object

    def resolve(**args)
      StarredProjectsFinder.new(user, params: args, current_user: current_user).execute
    end
  end
end
