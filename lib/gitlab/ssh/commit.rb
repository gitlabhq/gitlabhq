# frozen_string_literal: true

module Gitlab
  module Ssh
    class Commit < Gitlab::SignedCommit
      private

      def signature_class
        CommitSignatures::SshSignature
      end

      def attributes
        signature = ::Gitlab::Ssh::Signature.new(signature_text, signed_text, @commit.committer_email)

        {
          commit_sha: @commit.sha,
          project: @commit.project,
          key_id: signature.signed_by_key&.id,
          verification_status: signature.verification_status
        }
      end
    end
  end
end
