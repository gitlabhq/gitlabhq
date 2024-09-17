# frozen_string_literal: true

module Types
  class PagesDeploymentType < BaseObject
    graphql_name 'PagesDeployment'
    description 'Represents a pages deployment.'

    connection_type_class Types::CountableConnectionType
    authorize :read_pages_deployments

    field :active, GraphQL::Types::Boolean, null: false,
      description: 'Whether the deployment is currently active.', method: :active?
    field :ci_build_id, GraphQL::Types::ID, null: true,
      description: 'ID of the CI build that created the deployment.'
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false,
      description: 'Time the deployment was created.'
    field :deleted_at, GraphQL::Types::ISO8601DateTime, null: true,
      description: 'Time the deployment was deleted.'
    field :expires_at, GraphQL::Types::ISO8601DateTime, null: true,
      description: 'Time the deployment will expire.'
    field :file_count, GraphQL::Types::Int, null: true,
      description: 'Number of files that were published with the deployment.'
    field :id, GraphQL::Types::ID, null: false,
      description: 'ID of the Pages Deployment.'
    field :path_prefix, GraphQL::Types::String, null: true,
      description: 'URL path Prefix that points to the deployment.'
    field :project, Types::ProjectType, null: false,
      description: 'Project the deployment belongs to.'
    field :root_directory, GraphQL::Types::String, null: true,
      description: 'Path within the build assets that functions as the root directory for Pages sites.'
    field :size, GraphQL::Types::Int, null: true,
      description: 'Size of the storage used.'
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false,
      description: 'Time the deployment was last updated.'
    field :url, GraphQL::Types::String, null: false,
      description: 'Publicly accessible URL of the deployment.'

    def project
      ::Project.find(object.project_id)
    end
  end
end
