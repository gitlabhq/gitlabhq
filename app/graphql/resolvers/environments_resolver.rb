# frozen_string_literal: true

module Resolvers
  class EnvironmentsResolver < BaseResolver
    argument :name, GraphQL::STRING_TYPE,
              required: false,
              description: 'Name of the environment'

    argument :search, GraphQL::STRING_TYPE,
              required: false,
              description: 'Search query'

    type Types::EnvironmentType, null: true

    alias_method :project, :object

    def resolve(**args)
      return unless project.present?

      EnvironmentsFinder.new(project, context[:current_user], args).find
    end
  end
end
