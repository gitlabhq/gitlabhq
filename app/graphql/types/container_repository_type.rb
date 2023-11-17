# frozen_string_literal: true

module Types
  class ContainerRepositoryType < BaseObject
    graphql_name 'ContainerRepository'

    description 'A container repository'

    authorize :read_container_image

    expose_permissions Types::PermissionTypes::ContainerRepository

    field :can_delete, GraphQL::Types::Boolean,
      null: false,
      deprecated: {
        reason: 'Use `userPermissions` field. See `ContainerRepositoryPermissions` type',
        milestone: '16.7'
      },
      description: 'Can the current user delete the container repository.'
    field :created_at, Types::TimeType, null: false, description: 'Timestamp when the container repository was created.'
    field :expiration_policy_cleanup_status, Types::ContainerRepositoryCleanupStatusEnum, null: true, description: 'Tags cleanup status for the container repository.'
    field :expiration_policy_started_at, Types::TimeType, null: true, description: 'Timestamp when the cleanup done by the expiration policy was started on the container repository.'
    field :id, GraphQL::Types::ID, null: false, description: 'ID of the container repository.'
    field :last_cleanup_deleted_tags_count, GraphQL::Types::Int, null: true, description: 'Number of deleted tags from the last cleanup.'
    field :location, GraphQL::Types::String, null: false, description: 'URL of the container repository.'
    field :migration_state, GraphQL::Types::String, null: false, description: 'Migration state of the container repository.'
    field :name, GraphQL::Types::String, null: false, description: 'Name of the container repository.'
    field :path, GraphQL::Types::String, null: false, description: 'Path of the container repository.'
    field :project, Types::ProjectType, null: false, description: 'Project of the container registry.'
    field :status, Types::ContainerRepositoryStatusEnum, null: true, description: 'Status of the container repository.'
    field :tags_count, GraphQL::Types::Int, null: false, description: 'Number of tags associated with this image.'
    field :updated_at, Types::TimeType, null: false, description: 'Timestamp when the container repository was updated.'

    def can_delete
      Ability.allowed?(current_user, :update_container_image, object)
    end

    def project
      Gitlab::Graphql::Loaders::BatchModelLoader.new(Project, object.project_id).find
    end

    def tags_count
      object.tags_count
    rescue Faraday::Error
      raise ::Gitlab::Graphql::Errors::ResourceNotAvailable, 'We are having trouble connecting to the Container Registry. If this error persists, please review the troubleshooting documentation.'
    end
  end
end
