# frozen_string_literal: true

module Types
  class NamespaceType < BaseObject
    graphql_name 'Namespace'

    authorize :read_namespace

    field :id, GraphQL::ID_TYPE, null: false # rubocop:disable Graphql/Descriptions

    field :name, GraphQL::STRING_TYPE, null: false # rubocop:disable Graphql/Descriptions
    field :path, GraphQL::STRING_TYPE, null: false # rubocop:disable Graphql/Descriptions
    field :full_name, GraphQL::STRING_TYPE, null: false # rubocop:disable Graphql/Descriptions
    field :full_path, GraphQL::ID_TYPE, null: false # rubocop:disable Graphql/Descriptions

    field :description, GraphQL::STRING_TYPE, null: true # rubocop:disable Graphql/Descriptions
    markdown_field :description_html, null: true
    field :visibility, GraphQL::STRING_TYPE, null: true # rubocop:disable Graphql/Descriptions
    field :lfs_enabled, GraphQL::BOOLEAN_TYPE, null: true, method: :lfs_enabled? # rubocop:disable Graphql/Descriptions
    field :request_access_enabled, GraphQL::BOOLEAN_TYPE, null: true # rubocop:disable Graphql/Descriptions

    field :root_storage_statistics, Types::RootStorageStatisticsType,
          null: true,
          description: 'The aggregated storage statistics. Only available for root namespaces',
          resolve: -> (obj, _args, _ctx) { Gitlab::Graphql::Loaders::BatchRootStorageStatisticsLoader.new(obj.id).find }

    field :projects, # rubocop:disable Graphql/Descriptions
          Types::ProjectType.connection_type,
          null: false,
          resolver: ::Resolvers::NamespaceProjectsResolver
  end
end
