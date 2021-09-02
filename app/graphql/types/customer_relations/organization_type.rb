# frozen_string_literal: true

module Types
  module CustomerRelations
    class OrganizationType < BaseObject
      graphql_name 'CustomerRelationsOrganization'

      authorize :read_organization

      field :id,
            GraphQL::Types::ID,
            null: false,
            description: 'Internal ID of the organization.'

      field :name,
            GraphQL::Types::String,
            null: true,
            description: 'Name of the organization.'

      field :default_rate,
            GraphQL::Types::Float,
            null: true,
            description: 'Standard billing rate for the organization.'

      field :description,
            GraphQL::Types::String,
            null: true,
            description: 'Description or notes for the organization.'

      field :created_at,
            Types::TimeType,
            null: true,
            description: 'Timestamp the organization was created.'

      field :updated_at,
            Types::TimeType,
            null: true,
            description: 'Timestamp the organization was last updated.'
    end
  end
end
