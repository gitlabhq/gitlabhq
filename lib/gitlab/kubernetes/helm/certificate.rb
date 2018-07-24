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
          key = OpenSSL::PKey::RSA.new(4096)
          public_key = key.public_key

          subject = "/C=US"

          cert = OpenSSL::X509::Certificate.new
          cert.subject = cert.issuer = OpenSSL::X509::Name.parse(subject)
          cert.not_before = Time.now
          cert.not_after = INFINITE_EXPIRY.from_now
          cert.public_key = public_key
          cert.serial = 0x0
          cert.version = 2

          extension_factory = OpenSSL::X509::ExtensionFactory.new
          extension_factory.subject_certificate = cert
          extension_factory.issuer_certificate = cert
          cert.add_extension(extension_factory.create_extension('subjectKeyIdentifier', 'hash'))
          cert.add_extension(extension_factory.create_extension('basicConstraints', 'CA:TRUE', true))
          cert.add_extension(extension_factory.create_extension('keyUsage', 'cRLSign,keyCertSign', true))

          cert.sign key, OpenSSL::Digest::SHA256.new

          new(key, cert)
        end

        def issue(expires_in: SHORT_EXPIRY)
          key = OpenSSL::PKey::RSA.new(4096)
          public_key = key.public_key

          subject = "/C=US"

          cert = OpenSSL::X509::Certificate.new
          cert.subject = OpenSSL::X509::Name.parse(subject)
          cert.issuer = self.cert.subject
          cert.not_before = Time.now
          cert.not_after = expires_in.from_now
          cert.public_key = public_key
          cert.serial = 0x0
          cert.version = 2

          cert.sign self.key, OpenSSL::Digest::SHA256.new

          self.class.new(key, cert)
        end

        private

        def initialize(key, cert)
          @key = key
          @cert = cert
        end
      end
    end
  end
end
