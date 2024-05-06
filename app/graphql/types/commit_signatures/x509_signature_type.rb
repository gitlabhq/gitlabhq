# frozen_string_literal: true

module Types
  module CommitSignatures
    class X509SignatureType < Types::BaseObject
      graphql_name 'X509Signature'
      description 'X.509 signature for a signed commit'

      implements Types::CommitSignatureInterface

      authorize :download_code

      field :user, Types::UserType, null: true,
        method: :signed_by_user,
        calls_gitaly: true,
        description: 'User associated with the key.'

      field :x509_certificate, Types::X509CertificateType,
        null: true,
        description: 'Certificate used for the signature.'
    end
  end
end
