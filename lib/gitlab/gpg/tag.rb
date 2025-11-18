# frozen_string_literal: true

module Gitlab
  module Gpg
    class Tag < Gitlab::SignedTag
      include Gitlab::Utils::StrongMemoize

      def signature
        super

        Gpg::Signature.new(signature_text, signed_text, nil, context[:user_email])
      end
      strong_memoize_attr :signature

      def attributes
        return unless signature.gpg_key_primary_keyid

        {
          gpg_key: signature.gpg_key,
          gpg_key_user_name: signature.user_infos[:name],
          gpg_key_user_email: signature.user_infos[:email] || context[:user_email],
          gpg_key_primary_keyid: signature.gpg_key_primary_keyid,
          verification_status: signature.verification_status,
          project: @repository.container,
          object_name: object_name
        }
      end

      def signature_class
        ::Repositories::Tags::GpgSignature
      end
    end
  end
end
