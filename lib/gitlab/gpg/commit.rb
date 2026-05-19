# frozen_string_literal: true

module Gitlab
  module Gpg
    class Commit < Gitlab::Repositories::BaseSignedCommit
      def update_signature!(cached_signature)
        update_cached_signature!(cached_signature, gpg_signature.gpg_key)
      end

      def update_cached_signature!(cached_signature, gpg_key)
        cached_signature.update!(attributes(gpg_key))
        @signature = cached_signature
      end

      private

      def project
        @commit.project
      end

      def signature_class
        CommitSignatures::GpgSignature
      end

      def create_cached_signature!
        return unless gpg_signature.fingerprint

        attributes = attributes(nil)
        return CommitSignatures::GpgSignature.new(attributes) if Gitlab::Database.read_only?

        CommitSignatures::GpgSignature.safe_create!(attributes)
      end

      def attributes(gpg_key)
        {
          commit_sha: @commit.sha,
          project: project
        }.tap do |attrs|
          attrs[:committer_email] = committer_email if check_for_mailmapped_commit_emails?
          sig = gpg_signature(gpg_key:)
          gpg_key = sig.gpg_key
          attrs[:gpg_key] = gpg_key
          attrs[:gpg_key_primary_keyid] = gpg_key&.keyid || sig.fingerprint
          attrs[:verification_status] = sig.verification_status
          attrs[:gpg_key_user_name] = sig.user_infos[:name]
          attrs[:gpg_key_user_email] = sig.user_infos[:email]
        end
      end

      def gpg_signature(gpg_key: nil)
        strong_memoize_with(:gpg_signature, gpg_key) do
          ::Gitlab::Gpg::Signature.new(signature_text, signed_text, signer, @commit.committer_email,
            preloaded_gpg_key: gpg_key)
        end
      end
    end
  end
end
