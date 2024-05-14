# frozen_string_literal: true

module Types
  module CustomerRelations
    class ContactType < BaseObject
      graphql_name 'CustomerRelationsContact'

      authorize :read_crm_contact

      field :id,
        GraphQL::Types::ID,
        null: false,
        description: 'Internal ID of the contact.'

      field :organization, Types::CustomerRelations::OrganizationType,
        null: true,
        description: "Organization of the contact."

      field :first_name,
        GraphQL::Types::String,
        null: false,
        description: 'First name of the contact.'

      field :last_name,
        GraphQL::Types::String,
        null: false,
        description: 'Last name of the contact.'

      field :phone,
        GraphQL::Types::String,
        null: true,
        description: 'Phone number of the contact.'

      field :email,
        GraphQL::Types::String,
        null: true,
        description: 'Email address of the contact.'

      field :description,
        GraphQL::Types::String,
        null: true,
        description: 'Description of or notes for the contact.'

      field :created_at,
        Types::TimeType,
        null: false,
        description: 'Timestamp the contact was created.'

      field :updated_at,
        Types::TimeType,
        null: false,
        description: 'Timestamp the contact was last updated.'

      field :active,
        GraphQL::Types::Boolean,
        null: false,
        description: 'State of the contact.', method: :active?
    end
  end
end
