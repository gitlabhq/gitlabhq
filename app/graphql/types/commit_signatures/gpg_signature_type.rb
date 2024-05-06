# frozen_string_literal: true

module Types
  module CommitSignatures
    class GpgSignatureType < Types::BaseObject
      graphql_name 'GpgSignature'
      description 'GPG signature for a signed commit'

      implements Types::CommitSignatureInterface

      authorize :download_code

      field :user, Types::UserType, null: true,
        method: :signed_by_user,
        description: 'User associated with the key.'

      field :gpg_key_user_name, GraphQL::Types::String,
        null: true,
        description: 'User name associated with the GPG key.'

      field :gpg_key_user_email, GraphQL::Types::String,
        null: true,
        description: 'User email associated with the GPG key.'

      field :gpg_key_primary_keyid, GraphQL::Types::String,
        null: true,
        description: 'ID of the GPG key.'
    end
  end
end
