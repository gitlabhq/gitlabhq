# frozen_string_literal: true

module Types
  module ContainerRegistry
    class ContainerTagsExpirationPolicyType < BaseObject
      graphql_name 'ContainerTagsExpirationPolicy'

      description 'A tag expiration policy using regex patterns to control which images to keep or expire.'

      authorize :read_container_image

      field :cadence, Types::ContainerExpirationPolicyCadenceEnum,
        null: true,
        description: 'Schedule of the container expiration policy.',
        authorize: :admin_container_image

      field :created_at, Types::TimeType,
        null: true,
        description: 'Timestamp of when the container expiration policy was created.',
        authorize: :admin_container_image

      field :enabled, GraphQL::Types::Boolean,
        null: false,
        description: 'Indicates whether the container expiration policy is enabled.'

      field :keep_n, Types::ContainerExpirationPolicyKeepEnum,
        null: true,
        description: 'Number of tags to retain.',
        authorize: :admin_container_image

      field :name_regex, Types::UntrustedRegexp,
        null: true,
        description: 'Tags with names matching the regex pattern will expire.',
        authorize: :admin_container_image

      field :name_regex_keep, Types::UntrustedRegexp, # rubocop:disable GraphQL/ExtractType -- We don't want to extract this to a type, it's just a regex field
        null: true,
        description: 'Tags with names matching the regex pattern will be preserved.',
        authorize: :admin_container_image

      field :next_run_at, Types::TimeType,
        null: true,
        description: 'Next time that the container expiration policy will get executed.'

      field :older_than, Types::ContainerExpirationPolicyOlderThanEnum,
        null: true,
        description: 'Tags older than the given age will expire.',
        authorize: :admin_container_image

      field :updated_at, Types::TimeType,
        null: true,
        description: 'Timestamp of when the container expiration policy was updated.',
        authorize: :admin_container_image
    end
  end
end
