# frozen_string_literal: true

module Gitlab
  module Ssh
    class Tag < Gitlab::SignedTag
      include Gitlab::Utils::StrongMemoize

      def signature
        super

        Ssh::Signature.new(signature_text, signed_text, nil, tag_commit)
      end
      strong_memoize_attr :signature

      def attributes
        {
          key_id: signature.signed_by_key&.id,
          key_fingerprint_sha256: signature.key_fingerprint,
          verification_status: signature.verification_status,
          project: @repository.container,
          object_name: object_name
        }
      end

      def signature_class
        ::Repositories::Tags::SshSignature
      end

      private

      def tag_commit
        Struct.new(:committer_email, :project).new(context[:user_email], @repository.container)
      end
    end
  end
end
