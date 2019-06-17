# frozen_string_literal: true

module Gitlab
  module Gpg
    class Commit
      include Gitlab::Utils::StrongMemoize

      def initialize(commit)
        @commit = commit

        repo = commit.project.repository.raw_repository
        @signature_data = Gitlab::Git::Commit.extract_signature_lazily(repo, commit.sha || commit.id)
      end

      def signature_text
        strong_memoize(:signature_text) do
          @signature_data&.itself && @signature_data[0]
        end
      end

      def signed_text
        strong_memoize(:signed_text) do
          @signature_data&.itself && @signature_data[1]
        end
      end

      def has_signature?
        !!(signature_text && signed_text)
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def signature
        return unless has_signature?

        return @signature if @signature

        cached_signature = GpgSignature.find_by(commit_sha: @commit.sha)
        return @signature = cached_signature if cached_signature.present?

        @signature = create_cached_signature!
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def update_signature!(cached_signature)
        using_keychain do |gpg_key|
          cached_signature.update!(attributes(gpg_key))
          @signature = cached_signature
        end
      end

      private

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
          # Return the first signature for now: https://gitlab.com/gitlab-org/gitlab-ce/issues/54932
          break verified_signature
        end
      rescue GPGME::Error
        nil
      end

      def create_cached_signature!
        using_keychain do |gpg_key|
          attributes = attributes(gpg_key)
          break GpgSignature.new(attributes) if Gitlab::Database.read_only?

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
