# frozen_string_literal: true

module Types
  module AppConfig
    class InstanceMetadataType < ::Types::BaseObject
      graphql_name 'Metadata'

      authorize :read_instance_metadata
      authorize_granular_token permissions: :read_metadata, boundary: :instance, boundary_type: :instance

      field :enterprise, GraphQL::Types::Boolean, null: false,
        description: 'Enterprise edition.'
      field :feature_flags, [::Types::AppConfig::GitlabInstanceFeatureFlagType], null: false,
        description: 'Feature flags for the GitLab instance. ' \
          'External API consumers should read the [feature flag guidance]' \
          '(https://docs.gitlab.com/development/feature_flags/#do-not-use-feature-flags-in-external-api-consumers) ' \
          'before using this field.',
        experiment: { milestone: '17.4' },
        resolver: ::Resolvers::AppConfig::GitlabInstanceFeatureFlagsResolver
      field :kas, ::Types::AppConfig::KasType, null: false,
        description: 'Metadata about KAS.'
      field :revision, GraphQL::Types::String, null: false,
        description: 'Revision.'
      field :version, GraphQL::Types::String, null: false,
        description: 'Version.'
    end
  end
end
