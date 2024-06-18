# frozen_string_literal: true

module Resolvers
  class FeatureFlagResolver < BaseResolver
    type GraphQL::Types::Boolean, null: false

    argument :name, GraphQL::Types::String,
      required: true,
      description: 'Name of the feature flag.'

    def resolve(name:)
      return false unless current_user.present?

      Feature.enabled?(name.to_sym, current_user)
    end
  end
end
