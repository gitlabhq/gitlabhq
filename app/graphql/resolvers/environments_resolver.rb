# frozen_string_literal: true

module Resolvers
  class EnvironmentsResolver < BaseResolver
    argument :name, GraphQL::Types::String,
      required: false,
      description: 'Name of the environment.'

    argument :search, GraphQL::Types::String,
      required: false,
      description: 'Search query for environment name.'

    argument :states, [GraphQL::Types::String],
      required: false,
      description: 'States of environments that should be included in result.'

    argument :type, GraphQL::Types::String,
      required: false,
      description: 'Search query for environment type.'

    type Types::EnvironmentType, null: true

    alias_method :project, :object

    def resolve(**args)
      return unless project.present?

      ::Environments::EnvironmentsFinder.new(project, context[:current_user], args).execute
    rescue ::Environments::EnvironmentsFinder::InvalidStatesError => e
      raise Gitlab::Graphql::Errors::ArgumentError, e.message
    end
  end
end
