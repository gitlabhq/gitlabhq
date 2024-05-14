# frozen_string_literal: true

module Mutations
  module ReleaseAssetLinks
    class Delete < BaseMutation
      graphql_name 'ReleaseAssetLinkDelete'

      authorize :destroy_release

      ReleaseAssetLinkID = ::Types::GlobalIDType[::Releases::Link]

      argument :id, ReleaseAssetLinkID,
        required: true,
        description: 'ID of the release asset link to delete.'

      field :link,
        Types::ReleaseAssetLinkType,
        null: true,
        description: 'Deleted release asset link.'

      def resolve(id:)
        link = authorized_find!(id: id)

        result = ::Releases::Links::DestroyService
          .new(link.release, current_user)
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
