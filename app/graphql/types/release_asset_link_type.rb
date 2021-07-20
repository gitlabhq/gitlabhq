# frozen_string_literal: true

module Types
  class ReleaseAssetLinkType < BaseObject
    graphql_name 'ReleaseAssetLink'
    description 'Represents an asset link associated with a release'

    authorize :read_release

    field :id, GraphQL::ID_TYPE, null: false,
          description: 'ID of the link.'
    field :name, GraphQL::STRING_TYPE, null: true,
          description: 'Name of the link.'
    field :url, GraphQL::STRING_TYPE, null: true,
          description: 'URL of the link.'
    field :link_type, Types::ReleaseAssetLinkTypeEnum, null: true,
          description: 'Type of the link: `other`, `runbook`, `image`, `package`; defaults to `other`.'
    field :external, GraphQL::BOOLEAN_TYPE, null: true, method: :external?,
          description: 'Indicates the link points to an external resource.'

    field :direct_asset_url, GraphQL::STRING_TYPE, null: true,
          description: 'Direct asset URL of the link.'
    field :direct_asset_path, GraphQL::STRING_TYPE, null: true, method: :filepath,
          description: 'Relative path for the direct asset link.'

    def direct_asset_url
      return object.url unless object.filepath

      release = object.release.present
      release.download_url(object.filepath)
    end
  end
end
