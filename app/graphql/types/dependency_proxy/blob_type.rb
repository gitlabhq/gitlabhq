# frozen_string_literal: true

module Types
  class DependencyProxy::BlobType < BaseObject
    graphql_name 'DependencyProxyBlob'

    description 'Dependency proxy blob'

    authorize :read_dependency_proxy

    field :created_at, Types::TimeType, null: false, description: 'Date of creation.'
    field :file_name, GraphQL::Types::String, null: false, description: 'Name of the blob.'
    field :size, GraphQL::Types::String, null: false, description: 'Size of the blob file.'
    field :updated_at, Types::TimeType, null: false, description: 'Date of most recent update.'
  end
end
