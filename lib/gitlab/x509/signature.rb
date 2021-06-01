# frozen_string_literal: true
require 'openssl'
require 'digest'

module Gitlab
  module X509
    class Signature
      include Gitlab::Utils::StrongMemoize

      attr_reader :signature_text, :signed_text, :created_at

      def initialize(signature_text, signed_text, email, created_at)
        @signature_text = signature_text
        @signed_text = signed_text
        @email = email
        @created_at = created_at
      end

      def x509_certificate
        return if certificate_attributes.nil?

        X509Certificate.safe_create!(certificate_attributes) unless verified_signature.nil?
      end

      def user
        strong_memoize(:user) { User.find_by_any_email(@email) }
      end

      def verified_signature
        strong_memoize(:verified_signature) { verified_signature? }
      end

      def verification_status
        return :unverified if
          x509_certificate.nil? ||
          x509_certificate.revoked? ||
          !verified_signature ||
          user.nil?

        if user.verified_emails.include?(@email) && certificate_email == @email
          :verified
        else
          :unverified
        end
      end

      private

      def cert
        strong_memoize(:cert) do
          signer_certificate(p7) if valid_signature?
        end
      end

      def cert_store
        strong_memoize(:cert_store) do
          store = OpenSSL::X509::Store.new
          store.set_default_paths

          if Feature.enabled?(:x509_forced_cert_loading, type: :ops)
            # Forcibly load the default cert file because the OpenSSL library seemingly ignores it
            store.add_file(OpenSSL::X509::DEFAULT_CERT_FILE) if File.exist?(OpenSSL::X509::DEFAULT_CERT_FILE)
          end

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
        rescue StandardError
          nil
        end
      end

      def valid_signing_time?
        # rfc 5280 - 4.1.2.5  Validity
        # check if signed_time is within the time range (notBefore/notAfter)
        # non-rfc - git specific check: signed_time >= commit_time
        p7.signers[0].signed_time.between?(cert.not_before, cert.not_after) &&
          p7.signers[0].signed_time >= created_at
      end

      def valid_signature?
        p7.verify([], cert_store, signed_text, OpenSSL::PKCS7::NOVERIFY)
      rescue StandardError
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
      rescue StandardError
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
        return if extension.nil?

        crl_url = nil

        extension.each_line do |line|
          break if crl_url

          line.split('URI:').each do |item|
            item.strip

            if item.start_with?("http")
              crl_url = item.strip
              break
            end
          end
        end

        crl_url
      end

      def get_certificate_extension(extension)
        ext = cert.extensions.detect { |ext| ext.oid == extension }
        ext&.value
      end

      def issuer_subject_key_identifier
        key_identifier = get_certificate_extension('authorityKeyIdentifier')
        return if key_identifier.nil?

        key_identifier.gsub("keyid:", "").delete!("\n")
      end

      def certificate_subject_key_identifier
        key_identifier = get_certificate_extension('subjectKeyIdentifier')
        return if key_identifier.nil?

        key_identifier
      end

      def certificate_issuer
        cert.issuer.to_s(OpenSSL::X509::Name::RFC2253)
      end

      def certificate_subject
        cert.subject.to_s(OpenSSL::X509::Name::RFC2253)
      end

      def certificate_email
        email = nil

        get_certificate_extension('subjectAltName').split(',').each do |item|
          if item.strip.start_with?("email")
            email = item.split('email:')[1]
            break
          end
        end

        return if email.nil?

        email
      end

      def x509_issuer
        return if verified_signature.nil? || issuer_subject_key_identifier.nil? || certificate_crl.nil?

        attributes = {
          subject_key_identifier: issuer_subject_key_identifier,
          subject: certificate_issuer,
          crl_url: certificate_crl
        }

        X509Issuer.safe_create!(attributes) unless verified_signature.nil?
      end

      def certificate_attributes
        return if verified_signature.nil? || certificate_subject_key_identifier.nil? || x509_issuer.nil?

        {
          subject_key_identifier: certificate_subject_key_identifier,
          subject: certificate_subject,
          email: certificate_email,
          serial_number: cert.serial.to_i,
          x509_issuer_id: x509_issuer.id
        }
      end
    end
  end
end
