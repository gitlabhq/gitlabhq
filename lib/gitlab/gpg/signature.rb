# frozen_string_literal: true

module Gitlab
  module Gpg
    class Signature
      include Gitlab::Utils::StrongMemoize
      include SignatureType

      def initialize(signature_text, signed_text, signer, email, preloaded_gpg_key: nil)
        @signature_text = signature_text
        @signed_text = signed_text
        @signer = signer
        @email = email
        @preloaded_gpg_key = preloaded_gpg_key
      end

      attr_reader :signature_text, :signed_text, :email, :signer

      def type
        :gpg
      end

      def user_infos
        gpg_key&.verified_user_infos&.first || gpg_key&.user_infos&.first || {}
      end

      def verification_status
        keychain_attributes[:verification_status]
      end

      def gpg_key_primary_keyid
        gpg_key&.keyid || fingerprint
      end

      def gpg_key
        keychain_attributes[:gpg_key]
      end

      def fingerprint
        keychain_attributes[:fingerprint]
      end

      private

      def keychain_attributes
        Gitlab::Gpg.using_tmp_keychain do
          # first we need to get the fingerprint from the signature to query the gpg
          # key belonging to the fingerprint.
          # This way we can add the key to the temporary keychain and extract
          # the proper signature.
          # NOTE: the invoked method is #fingerprint but versions of GnuPG
          # prior to 2.2.13 return 16 characters (the format used by keyid)
          # instead of 40.
          signatures = gpg_signatures
          fp = signatures.first&.fingerprint

          break {} unless fp

          key = @preloaded_gpg_key || find_gpg_key(fp)

          if key
            Gitlab::Gpg::CurrentKeyChain.add(key.key)
            signatures = gpg_signatures
            fp = signatures.first&.fingerprint
          end

          {
            fingerprint: fp,
            gpg_key: key,
            verification_status: calculate_verification_status(signatures, key)
          }
        end
      end
      strong_memoize_attr :keychain_attributes

      def gpg_signatures
        signatures = []

        GPGME::Crypto.new.verify(signature_text, signed_text: signed_text) do |verified_signature|
          signatures << verified_signature
        end

        signatures
      rescue GPGME::Error
        []
      end

      def calculate_verification_status(signatures, key)
        return :verified_system if verified_by_gitlab?
        return :multiple_signatures if signatures.size > 1
        return :unknown_key unless key
        return :unverified_key unless key.verified?
        return :unverified unless signatures.first&.valid?

        if key.verified_and_belongs_to_email?(email)
          :verified
        elsif key.user.all_emails.include?(email)
          :same_user_different_email
        else
          :other_user
        end
      end

      # A commit signed by Gitaly returns `SIGNER_SYSTEM` as a signer
      # In order to calculate it, the signature is verified using the Gitaly's public key:
      # https://gitlab.com/gitlab-org/gitaly/-/blob/v16.2.0-rc2/internal/gitaly/service/commit/commit_signatures.go#L63
      #
      # It is safe to skip verification step if the commit has been signed by Gitaly
      def verified_by_gitlab?
        signer == :SIGNER_SYSTEM
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
