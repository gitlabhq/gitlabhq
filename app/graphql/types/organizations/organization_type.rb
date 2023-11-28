# frozen_string_literal: true

module Types
  module Organizations
    class OrganizationType < BaseObject
      graphql_name 'Organization'

      authorize :read_organization

      field :avatar_url,
        type: GraphQL::Types::String,
        null: true,
        description:
          'Avatar URL of the organization. `null` until ' \
          '[#422418](https://gitlab.com/gitlab-org/gitlab/-/issues/422418) is complete.',
        alpha: { milestone: '16.7' }
      field :description,
        GraphQL::Types::String,
        null: true,
        description: 'Description of the organization.',
        alpha: { milestone: '16.7' }
      field :groups,
        Types::GroupType.connection_type,
        null: false,
        description: 'Groups within this organization that the user has access to.',
        alpha: { milestone: '16.4' },
        resolver: ::Resolvers::Organizations::GroupsResolver
      field :id,
        GraphQL::Types::ID,
        null: false,
        description: 'ID of the organization.',
        alpha: { milestone: '16.4' }
      field :name,
        GraphQL::Types::String,
        null: false,
        description: 'Name of the organization.',
        alpha: { milestone: '16.4' }
      field :organization_users,
        null: false,
        description: 'Users with access to the organization.',
        alpha: { milestone: '16.4' },
        resolver: ::Resolvers::Organizations::OrganizationUsersResolver
      field :path,
        GraphQL::Types::String,
        null: false,
        description: 'Path of the organization.',
        alpha: { milestone: '16.4' }
      field :web_url,
        GraphQL::Types::String,
        null: false,
        description: 'Web URL of the organization.',
        alpha: { milestone: '16.6' }

      markdown_field :description_html, null: true, alpha: { milestone: '16.7' }, &:organization_detail

      # TODO - update to return real avatar url when https://gitlab.com/gitlab-org/gitlab/-/issues/422418 is complete.
      def avatar_url
        nil
      end
    end
  end
end
