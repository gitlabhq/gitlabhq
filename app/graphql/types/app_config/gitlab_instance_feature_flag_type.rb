# frozen_string_literal: true

module Types
  module AppConfig
    class GitlabInstanceFeatureFlagType < ::Types::BaseObject
      graphql_name 'GitlabInstanceFeatureFlag'
      description 'A feature flag for the GitLab instance.'

      authorize :read_instance_metadata

      field :enabled, ::GraphQL::Types::Boolean, null: false,
        description: 'Indicates whether the GitLab instance feature flag is enabled or not.'
      field :name, ::GraphQL::Types::String, null: false,
        description: 'Name of the GitLab instance feature flag.'
    end
  end
end
