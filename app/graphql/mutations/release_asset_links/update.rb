# frozen_string_literal: true

module Mutations
  module ReleaseAssetLinks
    class Update < BaseMutation
      graphql_name 'ReleaseAssetLinkUpdate'

      authorize :update_release

      ReleaseAssetLinkID = ::Types::GlobalIDType[::Releases::Link]

      argument :id, ReleaseAssetLinkID,
        required: true,
        description: 'ID of the release asset link to update.'

      argument :name, GraphQL::Types::String,
        required: false,
        description: 'Name of the asset link.'

      argument :url, GraphQL::Types::String,
        required: false,
        description: 'URL of the asset link.'

      argument :direct_asset_path, GraphQL::Types::String,
        required: false, as: :filepath,
        description: 'Relative path for a direct asset link.'

      argument :link_type, Types::ReleaseAssetLinkTypeEnum,
        required: false,
        description: 'Type of the asset link.'

      field :link,
        Types::ReleaseAssetLinkType,
        null: true,
        description: 'Asset link after mutation.'

      def ready?(**args)
        if args.key?(:link_type) && args[:link_type].nil?
          raise Gitlab::Graphql::Errors::ArgumentError,
            'if the linkType argument is provided, it cannot be null'
        end

        super
      end

      def resolve(id:, **link_attrs)
        link = authorized_find!(id: id)

        result = ::Releases::Links::UpdateService
          .new(link.release, current_user, link_attrs)
          .execute(link)

        if result.success?
          { link: result.payload[:link], errors: [] }
        else
          { link: nil, errors: result.message }
        end
      end
    end
  end
end
