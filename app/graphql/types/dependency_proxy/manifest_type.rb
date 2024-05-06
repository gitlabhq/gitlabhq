# frozen_string_literal: true

module Types
  class DependencyProxy::ManifestType < BaseObject
    graphql_name 'DependencyProxyManifest'

    description 'Dependency proxy manifest'

    authorize :read_dependency_proxy

    field :created_at, Types::TimeType, null: false, description: 'Date of creation.'
    field :digest, GraphQL::Types::String, null: false, description: 'Digest of the manifest.'
    field :file_name, GraphQL::Types::String, null: false, description: 'Name of the manifest.'
    field :id, ::Types::GlobalIDType[::DependencyProxy::Manifest], null: false, description: 'ID of the manifest.'
    field :image_name, GraphQL::Types::String, null: false, description: 'Name of the image.'
    field :size, GraphQL::Types::String, null: false, description: 'Size of the manifest file.'
    field :status,
      Types::DependencyProxy::ManifestTypeEnum,
      null: false,
      description: "Status of the manifest (#{::DependencyProxy::Manifest.statuses.keys.join(', ')})"
    field :updated_at, Types::TimeType, null: false, description: 'Date of most recent update.'

    def image_name
      object.file_name.chomp(File.extname(object.file_name))
    end
  end
end
