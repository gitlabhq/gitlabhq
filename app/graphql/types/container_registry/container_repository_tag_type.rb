# frozen_string_literal: true

module Types
  module ContainerRegistry
    class ContainerRepositoryTagType < BaseObject
      graphql_name 'ContainerRepositoryTag'

      description 'A tag from a container repository'

      authorize :read_container_image

      expose_permissions Types::PermissionTypes::ContainerRepositoryTag

      field :created_at, Types::TimeType, null: true, description: 'Timestamp when the tag was created.'
      field :digest, GraphQL::Types::String, null: true, description: 'Digest of the tag.'
      field :location, GraphQL::Types::String, null: false, description: 'URL of the tag.'
      field :media_type, GraphQL::Types::String, null: true, description: 'Media type of the tag.'
      field :name, GraphQL::Types::String, null: false, description: 'Name of the tag.'
      field :path, GraphQL::Types::String, null: false, description: 'Path of the tag.'
      field :published_at, Types::TimeType, null: true, description: 'Timestamp when the tag was published.'
      field :referrers, [Types::ContainerRegistry::ContainerRepositoryReferrerType], null: true,
        description: 'Referrers for the tag.'
      field :revision, GraphQL::Types::String, null: true, description: 'Revision of the tag.'
      field :short_revision, GraphQL::Types::String, null: true, description: 'Short revision of the tag.'
      field :total_size, GraphQL::Types::BigInt, null: true, description: 'Size of the tag.'

      field :protection,
        Types::ContainerRegistry::Protection::AccessLevelType,
        null: true,
        experiment: { milestone: '17.9' },
        method: :protection_rule,
        description: 'Minimum GitLab access level required to push and delete container image tags. ' \
          'If the value is `nil`, no minimum access level is enforced. ' \
          'Users with the Developer role or higher can push tags by default.'
    end
  end
end
