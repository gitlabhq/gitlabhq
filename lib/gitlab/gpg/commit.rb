module Gitlab
  module Gpg
    class Commit
      attr_reader :commit

      def initialize(commit)
        @commit = commit

        @signature_text, @signed_text = commit.raw.signature(commit.project.repository)
      end

      def has_signature?
        !!(@signature_text && @signed_text)
      end

      def signature
        return unless has_signature?

        cached_signature = GpgSignature.find_by(commit_sha: commit.sha)
        return cached_signature if cached_signature.present?

        Gitlab::Gpg.using_tmp_keychain do
          # first we need to get the keyid from the signature to query the gpg
          # key belonging to the keyid.
          # This way we can add the key to the temporary keychain and extract
          # the proper signature.
          gpg_key = GpgKey.find_by(primary_keyid: verified_signature.fingerprint)

          if gpg_key
            Gitlab::Gpg::CurrentKeyChain.add(gpg_key.key)
          end

          create_cached_signature!(gpg_key)
        end
      end

      private

      def verified_signature
        GPGME::Crypto.new.verify(@signature_text, signed_text: @signed_text) do |verified_signature|
          return verified_signature
        end
      end

      def create_cached_signature!(gpg_key)
        verified_signature_result = verified_signature

        GpgSignature.create!(
          commit_sha: commit.sha,
          project: commit.project,
          gpg_key: gpg_key,
          gpg_key_primary_keyid: gpg_key&.primary_keyid || verified_signature_result.fingerprint,
          valid_signature: !!(gpg_key && gpg_key.verified? && verified_signature_result.valid?)
        )
      end
    end
  end
end
