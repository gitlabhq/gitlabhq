# frozen_string_literal: true

module Types
  module Users
    class NamespaceCommitEmailType < BaseObject
      graphql_name 'NamespaceCommitEmail'

      authorize :read_user_email_address

      field :id,
        GraphQL::Types::ID,
        null: false,
        description: 'Internal ID of the namespace commit email.'

      field :email,
        Types::Users::EmailType,
        null: false,
        description: 'Email.'

      field :namespace,
        Types::NamespaceType,
        null: false,
        description: 'Namespace.'

      field :created_at,
        Types::TimeType,
        null: false,
        description: 'Timestamp the namespace commit email was created.'

      field :updated_at,
        Types::TimeType,
        null: false,
        description: 'Timestamp the namespace commit email was last updated.'
    end
  end
end
