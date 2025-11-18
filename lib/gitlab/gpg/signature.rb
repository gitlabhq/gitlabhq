# frozen_string_literal: true

module Gitlab
  module Gpg
    class Signature
      include Gitlab::Utils::StrongMemoize
      include SignatureType

      def initialize(signature_text, signed_text, signer, email)
        @signature_text = signature_text
        @signed_text = signed_text
        @signer = signer
        @email = email
      end

      attr_reader :signature_text, :signed_text, :email, :signer

      def type
        :gpg
      end

      def user_infos
        gpg_key&.verified_user_infos&.first || gpg_key&.user_infos&.first || {}
      end

      def verification_status
        using_keychain do
          break :verified_system if verified_by_gitlab?
          break :multiple_signatures if multiple_signatures?
          break :unknown_key unless gpg_key
          break :unverified_key unless gpg_key.verified?
          break :unverified unless verified_signature&.valid?

          if gpg_key.verified_and_belongs_to_email?(email)
            :verified
          elsif gpg_key.user.all_emails.include?(email)
            :same_user_different_email
          else
            :other_user
          end
        end
      end

      def gpg_key_primary_keyid
        gpg_key&.keyid || fingerprint
      end

      def gpg_key
        return unless fingerprint

        find_gpg_key(fingerprint)
      end
      strong_memoize_attr :gpg_key

      def fingerprint
        verified_signature&.fingerprint
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
          break unless fingerprint

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

      # If a commit is signed by Gitaly, the Gitaly returns `SIGNER_SYSTEM` as a signer
      # In order to calculate it, the signature is Verified using the Gitaly's public key:
      # https://gitlab.com/gitlab-org/gitaly/-/blob/v16.2.0-rc2/internal/gitaly/service/commit/commit_signatures.go#L63
      #
      # It is safe to skip verification step if the commit has been signed by Gitaly
      def verified_by_gitlab?
        signer == :SIGNER_SYSTEM
      end

      def multiple_signatures?
        gpg_signatures.size > 1
      end

      def gpg_signatures
        signatures = []

        GPGME::Crypto.new.verify(signature_text, signed_text: signed_text) do |verified_signature|
          signatures << verified_signature
        end

        signatures
      rescue GPGME::Error
        []
      end
      strong_memoize_attr :gpg_signatures

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
