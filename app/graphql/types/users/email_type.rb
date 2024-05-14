# frozen_string_literal: true

module Types
  module Users
    class EmailType < BaseObject
      graphql_name 'Email'

      authorize :read_user_email_address

      field :id,
        GraphQL::Types::ID,
        null: false,
        description: 'Internal ID of the email.'

      field :email,
        GraphQL::Types::String,
        null: false,
        description: 'Email address.'

      field :confirmed_at,
        Types::TimeType,
        null: true,
        description: 'Timestamp the email was confirmed.'

      field :created_at,
        Types::TimeType,
        null: false,
        description: 'Timestamp the email was created.'

      field :updated_at,
        Types::TimeType,
        null: false,
        description: 'Timestamp the email was last updated.'
    end
  end
end
