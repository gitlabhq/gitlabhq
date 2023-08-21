# frozen_string_literal: true

module Types
  module Organizations
    class OrganizationType < BaseObject
      graphql_name 'Organization'

      authorize :read_organization

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
      field :path,
        GraphQL::Types::String,
        null: false,
        description: 'Path of the organization.',
        alpha: { milestone: '16.4' }
    end
  end
end
