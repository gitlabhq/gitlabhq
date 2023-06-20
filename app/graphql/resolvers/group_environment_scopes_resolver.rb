# frozen_string_literal: true

module Resolvers
  class GroupEnvironmentScopesResolver < BaseResolver
    type Types::Ci::GroupEnvironmentScopeType.connection_type, null: true

    alias_method :group, :object

    argument :name, GraphQL::Types::String,
      required: false,
      description: 'Name of the environment scope.'

    argument :search, GraphQL::Types::String,
      required: false,
      description: 'Search query for environment scope name.'

    def resolve(**args)
      return unless group.present?

      ::Groups::EnvironmentScopesFinder.new(group: group, params: args).execute
    end
  end
end
