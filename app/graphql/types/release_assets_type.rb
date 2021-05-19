# frozen_string_literal: true

module Types
  class ReleaseAssetsType < BaseObject
    graphql_name 'ReleaseAssets'
    description 'A container for all assets associated with a release'

    authorize :read_release

    alias_method :release, :object

    present_using ReleasePresenter

    field :count, GraphQL::INT_TYPE, null: true, method: :assets_count,
          description: 'Number of assets of the release.'
    field :links, Types::ReleaseAssetLinkType.connection_type, null: true, method: :sorted_links,
          description: 'Asset links of the release.'
    field :sources, Types::ReleaseSourceType.connection_type, null: true,
          description: 'Sources of the release.'
  end
end
