module Gitlab
  module Gpg
    class Commit
      def initialize(commit)
        @commit = commit

        @signature_text, @signed_text =
          begin
            Rugged::Commit.extract_signature(@commit.project.repository.rugged, @commit.sha)
          rescue Rugged::OdbError
            nil
          end
      end

      def has_signature?
        !!(@signature_text && @signed_text)
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
          gpg_key = GpgKey.find_by(primary_keyid: verified_signature.fingerprint)

          if gpg_key
            Gitlab::Gpg::CurrentKeyChain.add(gpg_key.key)
            @verified_signature = nil
          end

          yield gpg_key
        end
      end

      def verified_signature
        @verified_signature ||= GPGME::Crypto.new.verify(@signature_text, signed_text: @signed_text) do |verified_signature|
          break verified_signature
        end
      end

      def create_cached_signature!
        using_keychain do |gpg_key|
          GpgSignature.create!(attributes(gpg_key))
        end
      end

      def attributes(gpg_key)
        user_infos = user_infos(gpg_key)
        verification_status = verification_status(gpg_key)

        {
          commit_sha: @commit.sha,
          project: @commit.project,
          gpg_key: gpg_key,
          gpg_key_primary_keyid: gpg_key&.primary_keyid || verified_signature.fingerprint,
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
    end
  end
end
