# frozen_string_literal: true

module Resolvers
  module AppConfig
    class GitlabInstanceFeatureFlagsResolver < BaseResolver
      # note: Set an arbitrary limit to avoid performance issues
      MAX_FEATURE_FLAG_NAMES = 20

      type [::Types::AppConfig::GitlabInstanceFeatureFlagType], null: false
      requires_argument!

      argument :names, [GraphQL::Types::String],
        required: true,
        description: "Names of the feature flags to lookup (maximum of #{MAX_FEATURE_FLAG_NAMES}).",
        validates: { length: { maximum: MAX_FEATURE_FLAG_NAMES } }

      def resolve(names:)
        return [] if names.empty?

        features = Feature.preload(names) # rubocop: disable CodeReuse/ActiveRecord -- Not an ActiveRecord method

        features
          .filter { |feature| Feature::Definition.has_definition?(feature.name) }
          .map { |feature| { name: feature.name, enabled: Feature.enabled?(feature.name, current_user) } }
      end
    end
  end
end
