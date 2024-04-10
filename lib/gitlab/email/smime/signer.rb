# frozen_string_literal: true

require 'openssl'

module Gitlab
  module Email
    module Smime
      # Tooling for signing and verifying data with SMIME
      class Signer
        # The `ca_certs` parameter, if provided, is an array of CA certificates
        # that will be attached in the signature together with the main `cert`.
        # This will be typically intermediate CAs
        def self.sign(cert:, key:, data:, ca_certs: nil)
          signed_data = OpenSSL::PKCS7.sign(cert, key, data, Array.wrap(ca_certs), OpenSSL::PKCS7::DETACHED)
          OpenSSL::PKCS7.write_smime(signed_data)
        end

        # Return nil if data cannot be verified, otherwise the signed content data
        #
        # Be careful with the `ca_certs` parameter, it will implicitly trust all the CAs
        # in the array by creating a trusted store, stopping validation at the first match
        # This is relevant when using intermediate CAs, `ca_certs` should only
        # include the trusted, root CA
        def self.verify_signature(signed_data:, ca_certs: nil)
          store = OpenSSL::X509::Store.new
          store.set_default_paths
          Array.wrap(ca_certs).compact.each { |ca_cert| store.add_cert(ca_cert) }

          signed_smime = OpenSSL::PKCS7.read_smime(signed_data)

          # The S/MIME certificate(s) are included in the message and the trusted
          # CAs are in the store parameter, so we pass no certs as parameters
          # to `PKCS7.verify`
          # See https://www.openssl.org/docs/manmaster/man3/PKCS7_verify.html
          signed_smime if signed_smime.verify(nil, store)
        end
      end
    end
  end
end
