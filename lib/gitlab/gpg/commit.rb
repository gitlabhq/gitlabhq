# frozen_string_literal: true

module Gitlab
  module Gpg
    class Commit < Gitlab::SignedCommit
      def update_signature!(cached_signature)
        using_keychain do |gpg_key|
          cached_signature.update!(attributes(gpg_key))
          @signature = cached_signature
        end
      end

      private

      def signature_class
        CommitSignatures::GpgSignature
      end

      def using_keychain
        Gitlab::Gpg.using_tmp_keychain do
          # first we need to get the fingerprint from the signature to query the gpg
          # key belonging to the fingerprint.
          # This way we can add the key to the temporary keychain and extract
          # the proper signature.
          # NOTE: the invoked method is #fingerprint but versions of GnuPG
          # prior to 2.2.13 return 16 characters (the format used by keyid)
          # instead of 40.
          fingerprint = verified_signature&.fingerprint

          break unless fingerprint

          gpg_key = find_gpg_key(fingerprint)

          if gpg_key
            Gitlab::Gpg::CurrentKeyChain.add(gpg_key.key)
            clear_memoization(:gpg_signatures)
          end

          yield gpg_key
        end
      end

      def verified_signature
        gpg_signatures.first
      end

      def create_cached_signature!
        using_keychain do |gpg_key|
          attributes = attributes(gpg_key)
          break CommitSignatures::GpgSignature.new(attributes) if Gitlab::Database.read_only?

          CommitSignatures::GpgSignature.safe_create!(attributes)
        end
      end

      def gpg_signatures
        strong_memoize(:gpg_signatures) do
          signatures = []

          GPGME::Crypto.new.verify(signature_text, signed_text: signed_text) do |verified_signature|
            signatures << verified_signature
          end

          signatures
        rescue GPGME::Error
          []
        end
      end

      def multiple_signatures?
        gpg_signatures.size > 1
      end

      def attributes(gpg_key)
        user_infos = user_infos(gpg_key)
        verification_status = verification_status(gpg_key)

        {
          commit_sha: @commit.sha,
          project: @commit.project,
          gpg_key: gpg_key,
          gpg_key_primary_keyid: gpg_key&.keyid || verified_signature&.fingerprint,
          gpg_key_user_name: user_infos[:name],
          gpg_key_user_email: gpg_key_user_email(user_infos, verification_status),
          verification_status: verification_status
        }
      end

      def verification_status(gpg_key)
        return :verified_system if verified_by_gitlab?
        return :multiple_signatures if multiple_signatures?
        return :unknown_key unless gpg_key
        return :unverified_key unless gpg_key.verified?
        return :unverified unless verified_signature&.valid?

        if gpg_key.verified_and_belongs_to_email?(@commit.committer_email)
          :verified
        elsif gpg_key.user.all_emails.include?(@commit.committer_email)
          :same_user_different_email
        else
          :other_user
        end
      end

      # If a commit is signed by Gitaly, the Gitaly returns `SIGNER_SYSTEM` as a signer
      # In order to calculate it, the signature is Verified using the Gitaly's public key:
      # https://gitlab.com/gitlab-org/gitaly/-/blob/v16.2.0-rc2/internal/gitaly/service/commit/commit_signatures.go#L63
      #
      # It is safe to skip verification step if the commit has been signed by Gitaly
      def verified_by_gitlab?
        signer == :SIGNER_SYSTEM
      end

      def user_infos(gpg_key)
        gpg_key&.verified_user_infos&.first || gpg_key&.user_infos&.first || {}
      end

      def find_gpg_key(fingerprint)
        if fingerprint.length > 16
          GpgKey.find_by_fingerprint(fingerprint) || GpgKeySubkey.find_by_fingerprint(fingerprint)
        else
          GpgKey.find_by_primary_keyid(fingerprint) || GpgKeySubkey.find_by_keyid(fingerprint)
        end
      end

      def gpg_key_user_email(user_infos, verification_status)
        return user_infos[:email] unless Feature.enabled?(:check_for_mailmapped_commit_emails,
          @commit.project) && verification_status == :verified_system

        user_infos[:email] || author_email
      end
    end
  end
end
