# frozen_string_literal: true

module Resolvers
  class FeatureFlagResolver < BaseResolver
    type GraphQL::Types::Boolean, null: false

    argument :name, GraphQL::Types::String,
      required: true,
      description: 'Name of the feature flag.'

    def resolve(name:)
      return false unless current_user.present?

      key = name.to_sym

      return false unless Feature::Definition.has_definition?(key)

      Feature.enabled?(key, current_user)
    end
  end
end
