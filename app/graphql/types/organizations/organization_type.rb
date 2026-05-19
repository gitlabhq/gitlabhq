# frozen_string_literal: true

module Types
  module Organizations
    # rubocop: disable Graphql/AuthorizeTypes -- authorization is enforced in OrganizationsFinder#by_user_access
    class OrganizationType < BaseObject
      graphql_name 'Organization'

      connection_type_class Types::CountableConnectionType

      authorize_granular_token permissions: :read_organization, boundary: :instance, boundary_type: :instance

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
      field :root_path,
        GraphQL::Types::String,
        null: false,
        description: 'Root path in the context of the organization.',
        experiment: { milestone: '18.5' }
      field :state,
        Types::Organizations::OrganizationStateEnum,
        null: false,
        description: 'State of the organization.',
        experiment: { milestone: '19.0' }
      field :visibility,
        GraphQL::Types::String,
        null: true,
        description: 'Visibility level of the organization.'
      field :web_path,
        GraphQL::Types::String,
        null: false,
        description: 'Web path of the organization.',
        experiment: { milestone: '19.0' }
      field :web_url, # rubocop:disable GraphQL/ExtractType -- web_url and web_path are semantically distinct (absolute URL vs. relative path) and should not be extracted into a composite type
        GraphQL::Types::String,
        null: false,
        description: 'Web URL of the organization.',
        experiment: { milestone: '16.6' }
      field :work_item_types, ::Types::WorkItems::TypeType.connection_type,
        null: true,
        description: 'Work item types available to the organization.',
        experiment: { milestone: '18.10' },
        resolver: ::Resolvers::WorkItems::TypesResolver

      markdown_field :description_html, null: true, experiment: { milestone: '16.7' }, &:organization_detail

      def avatar_url
        object.avatar_url(only_path: false)
      end

      def web_path
        object.web_url(only_path: true)
      end
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end

Types::Organizations::OrganizationType.prepend_mod
