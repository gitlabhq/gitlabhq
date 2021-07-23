# frozen_string_literal: true

module Types
  module ReleaseAssetLinkSharedInputArguments
    extend ActiveSupport::Concern

    included do
      argument :name, GraphQL::Types::String,
             required: true,
             description: 'Name of the asset link.'

      argument :url, GraphQL::Types::String,
             required: true,
             description: 'URL of the asset link.'

      argument :direct_asset_path, GraphQL::Types::String,
             required: false, as: :filepath,
             description: 'Relative path for a direct asset link.'

      argument :link_type, Types::ReleaseAssetLinkTypeEnum,
             required: false, default_value: 'other',
             description: 'The type of the asset link.'
    end
  end
end
