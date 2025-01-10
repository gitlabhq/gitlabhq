# frozen_string_literal: true

module Types
  module ContainerRegistry
    class ContainerRepositoryType < BaseObject
      graphql_name 'ContainerRepository'

      include Gitlab::Graphql::Authorize::AuthorizeResource

      PROTECTION_RULE_EXISTS_BATCH_SIZE = 20

      description 'A container repository'

      authorize :read_container_image

      expose_permissions Types::PermissionTypes::ContainerRepository

      field :created_at, Types::TimeType, null: false,
        description: 'Timestamp when the container repository was created.'
      field :expiration_policy_cleanup_status, Types::ContainerRegistry::ContainerRepositoryCleanupStatusEnum,
        null: true,
        description: 'Tags cleanup status for the container repository.'
      field :expiration_policy_started_at, Types::TimeType, null: true, # rubocop:disable GraphQL/ExtractType -- maintain current type
        description: 'Timestamp when the cleanup done by the expiration policy was started on the container repository.'
      field :id, GraphQL::Types::ID, null: false, description: 'ID of the container repository.'
      field :last_cleanup_deleted_tags_count, GraphQL::Types::Int, null: true,
        description: 'Number of deleted tags from the last cleanup.'
      field :location, GraphQL::Types::String, null: false, description: 'URL of the container repository.'
      field :migration_state, GraphQL::Types::String,
        null: false,
        description: 'Migration state of the container repository.',
        deprecated: {
          reason:
            'Returns an empty string. This was used for the migration of GitLab.com, which is now complete. ' \
            'Not used by Self-managed instances',
          milestone: '17.0'
        }
      field :name, GraphQL::Types::String, null: false, description: 'Name of the container repository.'
      field :path, GraphQL::Types::String, null: false, description: 'Path of the container repository.'
      field :project, Types::ProjectType, null: false, description: 'Project of the container registry.'
      field :protection_rule_exists, GraphQL::Types::Boolean,
        null: false,
        description:
          'Whether any matching container protection rule exists for the container repository.'
      field :status, Types::ContainerRegistry::ContainerRepositoryStatusEnum, null: true,
        description: 'Status of the container repository.'
      field :tags_count, GraphQL::Types::Int, null: false, description: 'Number of tags associated with the image.'
      field :updated_at, Types::TimeType, null: false,
        description: 'Timestamp when the container repository was updated.'

      def project
        Gitlab::Graphql::Loaders::BatchModelLoader.new(Project, object.project_id).find
      end

      def tags_count
        object.tags_count
      rescue Faraday::Error
        raise_resource_not_available_error!(
          'We are having trouble connecting to the Container Registry. ' \
            'If this error persists, please review the troubleshooting documentation.'
        )
      end

      # The migration has now completed and we are cleaning up the migration db columns.
      # For backward compatibility, we are keeping this field accessible.
      # This field will be removed in 18.0.
      def migration_state
        ''
      end

      def protection_rule_exists
        BatchLoader::GraphQL.for([object.project_id, object.path]).batch do |tuples, loader|
          tuples.each_slice(PROTECTION_RULE_EXISTS_BATCH_SIZE) do |projects_and_repository_paths|
            ::ContainerRegistry::Protection::Rule
              .for_push_exists_for_projects_and_repository_paths(projects_and_repository_paths)
              .each { |row| loader.call([row['project_id'], row['repository_path']], row['protected']) }
          end
        end
      end
    end
  end
end
