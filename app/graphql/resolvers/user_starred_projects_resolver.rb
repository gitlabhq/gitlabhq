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

    argument :min_access_level, ::Types::AccessLevelEnum,
      required: false,
      description: 'Return only projects where current user has at least the specified access level.'

    argument :programming_language_name, GraphQL::Types::String,
      required: false,
      description: 'Filter projects by programming language name (case insensitive). For example: "css" or "ruby".'

    alias_method :user, :object

    def resolve(**args)
      StarredProjectsFinder.new(
        user,
        params: {
          search: args[:search],
          sort: args[:sort],
          min_access_level: args[:min_access_level],
          language_name: args[:programming_language_name]
        },
        current_user: current_user
      ).execute
    end
  end
end
