# frozen_string_literal: true

module Types
  module Organizations
    class OrganizationType < BaseObject
      graphql_name 'Organization'

      connection_type_class Types::CountableConnectionType

      authorize :read_organization

      field :avatar_url,
        type: GraphQL::Types::String,
        null: true,
        description: 'Avatar URL of the organization.',
        experiment: { milestone: '16.7' }
      field :description,
        GraphQL::Types::String,
        null: true,
        description: 'Description of the organization.',
        experiment: { milestone: '16.7' }
      field :groups,
        Types::GroupType.connection_type,
        null: false,
        description: 'Groups within this organization that the user has access to.',
        experiment: { milestone: '16.4' },
        resolver: ::Resolvers::Organizations::GroupsResolver
      field :id,
        GraphQL::Types::ID,
        null: false,
        description: 'ID of the organization.',
        experiment: { milestone: '16.4' }
      field :name,
        GraphQL::Types::String,
        null: false,
        description: 'Name of the organization.',
        experiment: { milestone: '16.4' }
      field :organization_users,
        null: false,
        description: 'Users with access to the organization.',
        experiment: { milestone: '16.4' },
        resolver: ::Resolvers::Organizations::OrganizationUsersResolver
      field :path,
        GraphQL::Types::String,
        null: false,
        description: 'Path of the organization.',
        experiment: { milestone: '16.4' }
      field :projects, Types::ProjectType.connection_type, null: false,
        description: 'Projects within this organization that the user has access to.',
        experiment: { milestone: '16.8' },
        resolver: ::Resolvers::Organizations::ProjectsResolver
      field :web_url,
        GraphQL::Types::String,
        null: false,
        description: 'Web URL of the organization.',
        experiment: { milestone: '16.6' }

      markdown_field :description_html, null: true, experiment: { milestone: '16.7' }, &:organization_detail

      def avatar_url
        object.avatar_url(only_path: false)
      end
    end
  end
end
