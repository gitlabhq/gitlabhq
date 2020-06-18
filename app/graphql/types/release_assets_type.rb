# frozen_string_literal: true

module Types
  class ReleaseAssetsType < BaseObject
    graphql_name 'ReleaseAssets'

    authorize :read_release

    alias_method :release, :object

    present_using ReleasePresenter

    field :assets_count, GraphQL::INT_TYPE, null: true,
          description: 'Number of assets of the release'
    field :links, Types::ReleaseLinkType.connection_type, null: true,
          description: 'Asset links of the release'
    field :sources, Types::ReleaseSourceType.connection_type, null: true,
          description: 'Sources of the release'
  end
end
