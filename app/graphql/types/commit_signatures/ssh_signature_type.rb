# frozen_string_literal: true

module Types
  module CommitSignatures
    class SshSignatureType < Types::BaseObject
      graphql_name 'SshSignature'
      description 'SSH signature for a signed commit'

      implements Types::CommitSignatureInterface

      authorize :download_code

      field :user, Types::UserType,
        null: true,
        method: :signed_by_user,
        calls_gitaly: true,
        description: 'User associated with the key.'

      field :key, Types::KeyType,
        null: true,
        description: 'SSH key used for the signature.'

      field :key_fingerprint_sha256, String,
        null: true,
        description: 'Fingerprint of the key.'
    end
  end
end
