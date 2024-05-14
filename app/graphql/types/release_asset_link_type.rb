# frozen_string_literal: true

module Types
  class ReleaseAssetLinkType < BaseObject
    graphql_name 'ReleaseAssetLink'
    description 'Represents an asset link associated with a release'

    authorize :read_release

    present_using Releases::LinkPresenter

    field :id, GraphQL::Types::ID, null: false,
      description: 'ID of the link.'
    field :link_type,
      Types::ReleaseAssetLinkTypeEnum,
      null: true,
      description: 'Type of the link: `other`, `runbook`, `image`, `package`; defaults to `other`.'
    field :name, GraphQL::Types::String, null: true,
      description: 'Name of the link.'
    field :url, GraphQL::Types::String, null: true,
      description: 'URL of the link.'

    field :direct_asset_path, GraphQL::Types::String, null: true, method: :filepath,
      description: 'Relative path for the direct asset link.'
    field :direct_asset_url, GraphQL::Types::String, null: true,
      description: 'Direct asset URL of the link.'
  end
end
