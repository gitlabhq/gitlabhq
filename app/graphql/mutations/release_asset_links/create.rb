# frozen_string_literal: true

module Mutations
  module ReleaseAssetLinks
    class Create < Base
      graphql_name 'ReleaseAssetLinkCreate'

      authorize :create_release

      include Types::ReleaseAssetLinkSharedInputArguments

      field :link,
            Types::ReleaseAssetLinkType,
            null: true,
            description: 'The asset link after mutation.'

      def resolve(project_path:, tag:, **link_attrs)
        project = authorized_find!(project_path)
        release = project.releases.find_by_tag(tag)

        if release.nil?
          message = _('Release with tag "%{tag}" was not found') % { tag: tag }
          return { link: nil, errors: [message] }
        end

        new_link = release.links.create(link_attrs)

        unless new_link.persisted?
          return { link: nil, errors: new_link.errors.full_messages }
        end

        { link: new_link, errors: [] }
      end
    end
  end
end
