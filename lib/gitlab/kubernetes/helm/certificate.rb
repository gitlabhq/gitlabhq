module Gitlab
  module Kubernetes
    module Helm
      class Certificate
        INFINITE_EXPIRY = 1000.years
        SHORT_EXPIRY = 30.minutes

        attr_reader :key, :cert

        def key_string
          @key.to_s
        end

        def cert_string
          @cert.to_pem
        end

        def self.from_strings(key_string, cert_string)
          key = OpenSSL::PKey::RSA.new(key_string)
          cert = OpenSSL::X509::Certificate.new(cert_string)
          new(key, cert)
        end

        def self.generate_root
          _issue(signed_by: nil, expires_in: INFINITE_EXPIRY, ca: true)
        end

        def issue(expires_in: SHORT_EXPIRY)
          self.class._issue(signed_by: self, expires_in: expires_in, ca: false)
        end

        private

        def self._issue(signed_by:, expires_in:, ca:)
          key = OpenSSL::PKey::RSA.new(4096)
          public_key = key.public_key

          subject = OpenSSL::X509::Name.parse("/C=US")

          cert = OpenSSL::X509::Certificate.new
          cert.subject = subject

          cert.issuer = signed_by&.cert&.subject || subject

          cert.not_before = Time.now
          cert.not_after = expires_in.from_now
          cert.public_key = public_key
          cert.serial = 0x0
          cert.version = 2

          if ca
            extension_factory = OpenSSL::X509::ExtensionFactory.new
            extension_factory.subject_certificate = cert
            extension_factory.issuer_certificate = cert
            cert.add_extension(extension_factory.create_extension('subjectKeyIdentifier', 'hash'))
            cert.add_extension(extension_factory.create_extension('basicConstraints', 'CA:TRUE', true))
            cert.add_extension(extension_factory.create_extension('keyUsage', 'cRLSign,keyCertSign', true))
          end

          cert.sign(signed_by&.key || key, OpenSSL::Digest::SHA256.new)

          new(key, cert)
        end

        def initialize(key, cert)
          @key = key
          @cert = cert
        end
      end
    end
  end
end
