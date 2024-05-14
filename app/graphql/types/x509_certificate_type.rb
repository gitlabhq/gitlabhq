# frozen_string_literal: true

# rubocop:disable Graphql/AuthorizeTypes

module Types
  class X509CertificateType < Types::BaseObject
    graphql_name 'X509Certificate'
    description 'Represents an X.509 certificate.'

    field :certificate_status, GraphQL::Types::String,
      null: false,
      description: 'Indicates if the certificate is good or revoked.'

    field :created_at, Types::TimeType, null: false,
      description: 'Timestamp of when the certificate was saved.'

    field :email, GraphQL::Types::String, null: false,
      description: 'Email associated with the cerificate.'

    field :id, GraphQL::Types::ID, null: false, description: 'ID of the certificate.'

    field :serial_number, GraphQL::Types::String, null: false,
      description: 'Serial number of the certificate.'

    field :subject, GraphQL::Types::String, null: false, description: 'Subject of the certificate.'

    field :subject_key_identifier, GraphQL::Types::String,
      null: false,
      description: 'Subject key identifier of the certificate.'

    field :updated_at, Types::TimeType, null: false,
      description: 'Timestamp of when the certificate was last updated.'

    field :x509_issuer, Types::X509IssuerType, null: false,
      description: 'Issuer of the certificate.'
  end
end

# rubocop:enable Graphql/AuthorizeTypes
