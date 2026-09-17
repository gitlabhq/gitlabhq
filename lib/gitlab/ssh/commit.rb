# frozen_string_literal: true

module Gitlab
  module Ssh
    class Commit < Gitlab::Repositories::BaseSignedCommit
      include Gitlab::Repositories::ProjectScopedSignature

      private

      def signature_class
        CommitSignatures::SshSignature
      end

      def attributes
        signature = ::Gitlab::Ssh::Signature.new(signature_text, signed_text, signer, @commit)

        {
          commit_sha: @commit.sha,
          project: @commit.project,
          key_id: signature.signed_by_key&.id,
          key_fingerprint_sha256: signature.key_fingerprint,
          user_id: signature.user_id,
          verification_status: signature.verification_status,
          committer_email: committer_email
        }
      end
    end
  end
end
