# frozen_string_literal: true

module Types
  class NamespaceType < BaseObject
    graphql_name 'Namespace'

    authorize :read_namespace

    field :id, GraphQL::ID_TYPE, null: false

    field :name, GraphQL::STRING_TYPE, null: false
    field :path, GraphQL::STRING_TYPE, null: false
    field :full_name, GraphQL::STRING_TYPE, null: false
    field :full_path, GraphQL::ID_TYPE, null: false

    field :description, GraphQL::STRING_TYPE, null: true
    markdown_field :description_html, null: true
    field :visibility, GraphQL::STRING_TYPE, null: true
    field :lfs_enabled, GraphQL::BOOLEAN_TYPE, null: true, method: :lfs_enabled?
    field :request_access_enabled, GraphQL::BOOLEAN_TYPE, null: true

    field :projects,
          Types::ProjectType.connection_type,
          null: false,
          resolver: ::Resolvers::NamespaceProjectsResolver
  end
end
