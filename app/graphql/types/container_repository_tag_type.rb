# frozen_string_literal: true

module Types
  class ContainerRepositoryTagType < BaseObject
    graphql_name 'ContainerRepositoryTag'

    description 'A tag from a container repository'

    authorize :read_container_image

    field :name, GraphQL::Types::String, null: false, description: 'Name of the tag.'
    field :path, GraphQL::Types::String, null: false, description: 'Path of the tag.'
    field :location, GraphQL::Types::String, null: false, description: 'URL of the tag.'
    field :digest, GraphQL::Types::String, null: true, description: 'Digest of the tag.'
    field :revision, GraphQL::Types::String, null: true, description: 'Revision of the tag.'
    field :short_revision, GraphQL::Types::String, null: true, description: 'Short revision of the tag.'
    field :total_size, GraphQL::Types::BigInt, null: true, description: 'The size of the tag.'
    field :created_at, Types::TimeType, null: true, description: 'Timestamp when the tag was created.'
    field :can_delete, GraphQL::Types::Boolean, null: false, description: 'Can the current user delete this tag.'

    def can_delete
      Ability.allowed?(current_user, :destroy_container_image, object)
    end
  end
end
