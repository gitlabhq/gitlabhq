# frozen_string_literal: true

require 'openssl'

module Gitlab
  module Email
    module Smime
      # Tooling for signing and verifying data with SMIME
      class Signer
        include OpenSSL

        def self.sign(cert:, key:, data:)
          signed_data = PKCS7.sign(cert, key, data, nil, PKCS7::DETACHED)
          PKCS7.write_smime(signed_data)
        end

        # return nil if data cannot be verified, otherwise the signed content data
        def self.verify_signature(cert:, ca_cert: nil, signed_data:)
          store = X509::Store.new
          store.set_default_paths
          store.add_cert(ca_cert) if ca_cert

          signed_smime = PKCS7.read_smime(signed_data)
          signed_smime if signed_smime.verify([cert], store)
        end
      end
    end
  end
end
