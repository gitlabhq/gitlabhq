# frozen_string_literal: true

# rubocop:disable Graphql/AuthorizeTypes

module Types
  class X509IssuerType < Types::BaseObject
    graphql_name 'X509Issuer'
    description 'Issuer of an X.509 certificate.'

    field :created_at, Types::TimeType, null: true,
      description: 'Timestamp of when the issuer was created.'

    field :crl_url, GraphQL::Types::String, null: true,
      description: 'Certificate revokation list of the issuer.'

    field :id, GraphQL::Types::ID, null: true, description: 'ID of the issuer.'

    field :subject, GraphQL::Types::String, null: true, description: 'Subject of the issuer.'

    field :subject_key_identifier, GraphQL::Types::String,
      null: true,
      description: 'Subject key identifier of the issuer.'

    field :updated_at, Types::TimeType, null: true,
      description: 'Timestamp of when the issuer was last updated.'
  end
end

# rubocop:enable Graphql/AuthorizeTypes
