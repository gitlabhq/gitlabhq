# frozen_string_literal: true

module Resolvers
  class EnvironmentsResolver < BaseResolver
    argument :name, GraphQL::STRING_TYPE,
              required: false,
              description: 'Name of the environment.'

    argument :search, GraphQL::STRING_TYPE,
              required: false,
              description: 'Search query for environment name.'

    argument :states, [GraphQL::STRING_TYPE],
              required: false,
              description: 'States of environments that should be included in result.'

    type Types::EnvironmentType, null: true

    alias_method :project, :object

    def resolve(**args)
      return unless project.present?

      Environments::EnvironmentsFinder.new(project, context[:current_user], args).execute
    rescue Environments::EnvironmentsFinder::InvalidStatesError => exception
      raise Gitlab::Graphql::Errors::ArgumentError, exception.message
    end
  end
end
