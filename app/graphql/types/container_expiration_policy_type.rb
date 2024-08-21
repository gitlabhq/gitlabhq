# frozen_string_literal: true

module Types
  class ContainerExpirationPolicyType < BaseObject
    graphql_name 'ContainerExpirationPolicy'

    description 'A tag expiration policy designed to keep only the images that matter most'

    authorize :admin_container_image

    field :cadence, Types::ContainerExpirationPolicyCadenceEnum, null: false, description: 'This container expiration policy schedule.'
    field :created_at, Types::TimeType, null: false, description: 'Timestamp of when the container expiration policy was created.'
    field :enabled, GraphQL::Types::Boolean, null: false, description: 'Indicates whether the container expiration policy is enabled.'
    field :keep_n, Types::ContainerExpirationPolicyKeepEnum, null: true, description: 'Number of tags to retain.'
    field :name_regex, Types::UntrustedRegexp, null: true, description: 'Tags with names matching the regex pattern will expire.'
    field :name_regex_keep, Types::UntrustedRegexp, null: true, description: 'Tags with names matching the regex pattern will be preserved.'
    field :next_run_at, Types::TimeType, null: true, description: 'Next time that the container expiration policy will get executed.'
    field :older_than, Types::ContainerExpirationPolicyOlderThanEnum, null: true, description: 'Tags older than the given age will expire.'
    field :updated_at, Types::TimeType, null: false, description: 'Timestamp of when the container expiration policy was updated.'
  end
end
