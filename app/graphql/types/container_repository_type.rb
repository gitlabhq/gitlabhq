# frozen_string_literal: true

module Types
  class ContainerRepositoryType < BaseObject
    graphql_name 'ContainerRepository'

    description 'A container repository'

    authorize :read_container_image

    field :id, GraphQL::ID_TYPE, null: false, description: 'ID of the container repository.'
    field :name, GraphQL::STRING_TYPE, null: false, description: 'Name of the container repository.'
    field :path, GraphQL::STRING_TYPE, null: false, description: 'Path of the container repository.'
    field :location, GraphQL::STRING_TYPE, null: false, description: 'URL of the container repository.'
    field :created_at, Types::TimeType, null: false, description: 'Timestamp when the container repository was created.'
    field :updated_at, Types::TimeType, null: false, description: 'Timestamp when the container repository was updated.'
    field :expiration_policy_started_at, Types::TimeType, null: true, description: 'Timestamp when the cleanup done by the expiration policy was started on the container repository.'
    field :expiration_policy_cleanup_status, Types::ContainerRepositoryCleanupStatusEnum, null: true, description: 'The tags cleanup status for the container repository.'
    field :status, Types::ContainerRepositoryStatusEnum, null: true, description: 'Status of the container repository.'
    field :tags_count, GraphQL::INT_TYPE, null: false, description: 'Number of tags associated with this image.'
    field :can_delete, GraphQL::BOOLEAN_TYPE, null: false, description: 'Can the current user delete the container repository.'

    def can_delete
      Ability.allowed?(current_user, :update_container_image, object)
    end
  end
end
