# frozen_string_literal: true
require 'openssl'
require 'digest'

module Gitlab
  module X509
    class Commit < Gitlab::SignedCommit
      def signature
        super

        return @signature if @signature

        cached_signature = lazy_signature&.itself
        return @signature = cached_signature if cached_signature.present?

        @signature = create_cached_signature!
      end

      def update_signature!(cached_signature)
        cached_signature.update!(attributes)
        @signature = cached_signature
      end

      private

      def lazy_signature
        BatchLoader.for(@commit.sha).batch do |shas, loader|
          X509CommitSignature.by_commit_sha(shas).each do |signature|
            loader.call(signature.commit_sha, signature)
          end
        end
      end

      def verified_signature
        strong_memoize(:verified_signature) { verified_signature? }
      end

      def cert
        strong_memoize(:cert) do
          signer_certificate(p7) if valid_signature?
        end
      end

      def cert_store
        strong_memoize(:cert_store) do
          store = OpenSSL::X509::Store.new
          store.set_default_paths
          # valid_signing_time? checks the time attributes already
          # this flag is required, otherwise expired certificates would become
          # unverified when notAfter within certificate attribute is reached
          store.flags = OpenSSL::X509::V_FLAG_NO_CHECK_TIME
          store
        end
      end

      def p7
        strong_memoize(:p7) do
          pkcs7_text = signature_text.sub('-----BEGIN SIGNED MESSAGE-----', '-----BEGIN PKCS7-----')
          pkcs7_text = pkcs7_text.sub('-----END SIGNED MESSAGE-----', '-----END PKCS7-----')

          OpenSSL::PKCS7.new(pkcs7_text)
        rescue
          nil
        end
      end

      def valid_signing_time?
        # rfc 5280 - 4.1.2.5  Validity
        # check if signed_time is within the time range (notBefore/notAfter)
        # non-rfc - git specific check: signed_time >= commit_time
        p7.signers[0].signed_time.between?(cert.not_before, cert.not_after) &&
          p7.signers[0].signed_time >= @commit.created_at
      end

      def valid_signature?
        p7.verify([], cert_store, signed_text, OpenSSL::PKCS7::NOVERIFY)
      rescue
        nil
      end

      def verified_signature?
        # verify has multiple options but only a boolean return value
        # so first verify without certificate chain
        if valid_signature?
          if valid_signing_time?
            # verify with system certificate chain
            p7.verify([], cert_store, signed_text)
          else
            false
          end
        else
          nil
        end
      rescue
        nil
      end

      def signer_certificate(p7)
        p7.certificates.each do |cert|
          next if cert.serial != p7.signers[0].serial

          return cert
        end
      end

      def certificate_crl
        extension = get_certificate_extension('crlDistributionPoints')
        extension.split('URI:').each do |item|
          item.strip

          if item.start_with?("http")
            return item.strip
          end
        end
      end

      def get_certificate_extension(extension)
        cert.extensions.each do |ext|
          if ext.oid == extension
            return ext.value
          end
        end
      end

      def issuer_subject_key_identifier
        get_certificate_extension('authorityKeyIdentifier').gsub("keyid:", "").delete!("\n")
      end

      def certificate_subject_key_identifier
        get_certificate_extension('subjectKeyIdentifier')
      end

      def certificate_issuer
        cert.issuer.to_s(OpenSSL::X509::Name::RFC2253)
      end

      def certificate_subject
        cert.subject.to_s(OpenSSL::X509::Name::RFC2253)
      end

      def certificate_email
        get_certificate_extension('subjectAltName').split('email:')[1]
      end

      def issuer_attributes
        return if verified_signature.nil?

        {
          subject_key_identifier: issuer_subject_key_identifier,
          subject: certificate_issuer,
          crl_url: certificate_crl
        }
      end

      def certificate_attributes
        return if verified_signature.nil?

        issuer = X509Issuer.safe_create!(issuer_attributes)

        {
          subject_key_identifier: certificate_subject_key_identifier,
          subject: certificate_subject,
          email: certificate_email,
          serial_number: cert.serial,
          x509_issuer_id: issuer.id
        }
      end

      def attributes
        return if verified_signature.nil?

        certificate = X509Certificate.safe_create!(certificate_attributes)

        {
          commit_sha: @commit.sha,
          project: @commit.project,
          x509_certificate_id: certificate.id,
          verification_status: verification_status
        }
      end

      def verification_status
        if verified_signature && certificate_email == @commit.committer_email
          :verified
        else
          :unverified
        end
      end

      def create_cached_signature!
        return if verified_signature.nil?

        return X509CommitSignature.new(attributes) if Gitlab::Database.read_only?

        X509CommitSignature.safe_create!(attributes)
      end
    end
  end
end
