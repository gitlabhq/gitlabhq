# frozen_string_literal: true

module Types
  class ContainerExpirationPolicyType < BaseObject
    graphql_name 'ContainerExpirationPolicy'

    description 'A tag expiration policy designed to keep only the images that matter most'

    authorize :destroy_container_image

    field :created_at, Types::TimeType, null: false, description: 'Timestamp of when the container expiration policy was created.'
    field :updated_at, Types::TimeType, null: false, description: 'Timestamp of when the container expiration policy was updated.'
    field :enabled, GraphQL::Types::Boolean, null: false, description: 'Indicates whether this container expiration policy is enabled.'
    field :older_than, Types::ContainerExpirationPolicyOlderThanEnum, null: true, description: 'Tags older that this will expire.'
    field :cadence, Types::ContainerExpirationPolicyCadenceEnum, null: false, description: 'This container expiration policy schedule.'
    field :keep_n, Types::ContainerExpirationPolicyKeepEnum, null: true, description: 'Number of tags to retain.'
    field :name_regex, Types::UntrustedRegexp, null: true, description: 'Tags with names matching this regex pattern will expire.'
    field :name_regex_keep, Types::UntrustedRegexp, null: true, description: 'Tags with names matching this regex pattern will be preserved.'
    field :next_run_at, Types::TimeType, null: true, description: 'Next time that this container expiration policy will get executed.'
  end
end
