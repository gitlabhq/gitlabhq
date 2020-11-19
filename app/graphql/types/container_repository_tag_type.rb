# frozen_string_literal: true

module Types
  class ContainerRepositoryTagType < BaseObject
    graphql_name 'ContainerRepositoryTag'

    description 'A tag from a container repository'

    authorize :read_container_image

    field :name, GraphQL::STRING_TYPE, null: false, description: 'Name of the tag.'
    field :path, GraphQL::STRING_TYPE, null: false, description: 'Path of the tag.'
    field :location, GraphQL::STRING_TYPE, null: false, description: 'URL of the tag.'
    field :digest, GraphQL::STRING_TYPE, null: false, description: 'Digest of the tag.'
    field :revision, GraphQL::STRING_TYPE, null: false, description: 'Revision of the tag.'
    field :short_revision, GraphQL::STRING_TYPE, null: false, description: 'Short revision of the tag.'
    field :total_size, GraphQL::INT_TYPE, null: false, description: 'The size of the tag.'
    field :created_at, Types::TimeType, null: false, description: 'Timestamp when the tag was created.'
    field :can_delete, GraphQL::BOOLEAN_TYPE, null: false, description: 'Can the current user delete this tag.'

    def can_delete
      Ability.allowed?(current_user, :destroy_container_image, object)
    end
  end
end
