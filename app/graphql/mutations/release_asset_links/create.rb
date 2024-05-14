# frozen_string_literal: true

module Mutations
  module ReleaseAssetLinks
    class Create < BaseMutation
      graphql_name 'ReleaseAssetLinkCreate'

      include FindsProject
      include Types::ReleaseAssetLinkSharedInputArguments

      authorize :create_release

      argument :project_path, GraphQL::Types::ID,
        required: true,
        description: 'Full path of the project the asset link is associated with.'

      argument :tag_name, GraphQL::Types::String,
        required: true, as: :tag,
        description: "Name of the associated release's tag."

      field :link,
        Types::ReleaseAssetLinkType,
        null: true,
        description: 'Asset link after mutation.'

      def resolve(project_path:, tag:, **link_attrs)
        project = authorized_find!(project_path)
        release = project.releases.find_by_tag(tag)

        if release.nil?
          message = _('Release with tag "%{tag}" was not found') % { tag: tag }
          return { link: nil, errors: [message] }
        end

        raise_resource_not_available_error! unless Ability.allowed?(current_user, :update_release, release)

        result = ::Releases::Links::CreateService
          .new(release, current_user, link_attrs)
          .execute

        if result.success?
          { link: result.payload[:link], errors: [] }
        else
          { link: nil, errors: result.message }
        end
      end
    end
  end
end
