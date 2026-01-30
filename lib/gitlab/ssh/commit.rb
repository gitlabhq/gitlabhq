# frozen_string_literal: true

module Gitlab
  module Ssh
    class Commit < Gitlab::Repositories::BaseSignedCommit
      extend ::Gitlab::Utils::Override

      private

      override :lazy_signature
      def lazy_signature
        BatchLoader.for([@commit.project.id, @commit.sha]).batch do |project_sha_pairs, loader|
          project_ids = project_sha_pairs.map(&:first).uniq
          shas = project_sha_pairs.map(&:last).uniq

          signature_class.by_commit_shas_and_project_ids(shas, project_ids).each do |signature|
            loader.call([signature.project_id, signature.commit_sha], signature)
          end
        end
      end

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
          verification_status: signature.verification_status
        }.tap do |attrs|
          attrs[:committer_email] = committer_email if check_for_mailmapped_commit_emails?
        end
      end
    end
  end
end
