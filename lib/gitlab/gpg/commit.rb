# frozen_string_literal: true

module Gitlab
  module Gpg
    class Commit < Gitlab::SignedCommit
      def signature
        super

        return @signature if @signature

        cached_signature = lazy_signature&.itself
        return @signature = cached_signature if cached_signature.present?

        @signature = create_cached_signature!
      end

      def update_signature!(cached_signature)
        using_keychain do |gpg_key|
          cached_signature.update!(attributes(gpg_key))
          @signature = cached_signature
        end
      end

      private

      def lazy_signature
        BatchLoader.for(@commit.sha).batch do |shas, loader|
          GpgSignature.by_commit_sha(shas).each do |signature|
            loader.call(signature.commit_sha, signature)
          end
        end
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
            clear_memoization(:verified_signature)
          end

          yield gpg_key
        end
      end

      def verified_signature
        strong_memoize(:verified_signature) { gpgme_signature }
      end

      def gpgme_signature
        GPGME::Crypto.new.verify(signature_text, signed_text: signed_text) do |verified_signature|
          # Return the first signature for now: https://gitlab.com/gitlab-org/gitlab-foss/issues/54932
          break verified_signature
        end
      rescue GPGME::Error
        nil
      end

      def create_cached_signature!
        using_keychain do |gpg_key|
          attributes = attributes(gpg_key)
          break GpgSignature.new(attributes) if Gitlab::Database.main.read_only?

          GpgSignature.safe_create!(attributes)
        end
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
          gpg_key_user_email: user_infos[:email],
          verification_status: verification_status
        }
      end

      def verification_status(gpg_key)
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
    end
  end
end
