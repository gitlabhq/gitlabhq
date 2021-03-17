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
            description: 'The deleted release asset link.'

      def resolve(id:)
        link = authorized_find!(id)

        unless link.destroy
          return { link: nil, errors: link.errors.full_messages }
        end

        { link: link, errors: [] }
      end

      def find_object(id)
        # TODO: remove this line when the compatibility layer is removed
        # See: https://gitlab.com/gitlab-org/gitlab/-/issues/257883
        id = ReleaseAssetLinkID.coerce_isolated_input(id)

        GitlabSchema.find_by_gid(id)
      end
    end
  end
end
