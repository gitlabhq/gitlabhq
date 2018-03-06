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

      def signature
        return unless has_signature?

        return @signature if @signature

        cached_signature = GpgSignature.find_by(commit_sha: @commit.sha)
        return @signature = cached_signature if cached_signature.present?

        @signature = create_cached_signature!
      end

      def update_signature!(cached_signature)
        using_keychain do |gpg_key|
          cached_signature.update_attributes!(attributes(gpg_key))
        end

        @signature = cached_signature
      end

      private

      def using_keychain
        Gitlab::Gpg.using_tmp_keychain do
          # first we need to get the keyid from the signature to query the gpg
          # key belonging to the keyid.
          # This way we can add the key to the temporary keychain and extract
          # the proper signature.
          # NOTE: the invoked method is #fingerprint but it's only returning
          # 16 characters (the format used by keyid) instead of 40.
          gpg_key = find_gpg_key(verified_signature.fingerprint)

          if gpg_key
            Gitlab::Gpg::CurrentKeyChain.add(gpg_key.key)
            @verified_signature = nil
          end

          yield gpg_key
        end
      end

      def verified_signature
        @verified_signature ||= GPGME::Crypto.new.verify(signature_text, signed_text: signed_text) do |verified_signature|
          break verified_signature
        end
      end

      def create_cached_signature!
        using_keychain do |gpg_key|
          signature = GpgSignature.new(attributes(gpg_key))
          signature.save! unless Gitlab::Database.read_only?
          signature
        end
      end

      def attributes(gpg_key)
        user_infos = user_infos(gpg_key)
        verification_status = verification_status(gpg_key)

        {
          commit_sha: @commit.sha,
          project: @commit.project,
          gpg_key: gpg_key,
          gpg_key_primary_keyid: gpg_key&.keyid || verified_signature.fingerprint,
          gpg_key_user_name: user_infos[:name],
          gpg_key_user_email: user_infos[:email],
          verification_status: verification_status
        }
      end

      def verification_status(gpg_key)
        return :unknown_key unless gpg_key
        return :unverified_key unless gpg_key.verified?
        return :unverified unless verified_signature.valid?

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

      def find_gpg_key(keyid)
        GpgKey.find_by(primary_keyid: keyid) || GpgKeySubkey.find_by(keyid: keyid)
      end
    end
  end
end
