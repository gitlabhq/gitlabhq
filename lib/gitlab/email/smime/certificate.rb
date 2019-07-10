# frozen_string_literal: true

module Gitlab
  module Email
    module Smime
      class Certificate
        include OpenSSL

        attr_reader :key, :cert

        def key_string
          @key.to_s
        end

        def cert_string
          @cert.to_pem
        end

        def self.from_strings(key_string, cert_string)
          key = PKey::RSA.new(key_string)
          cert = X509::Certificate.new(cert_string)
          new(key, cert)
        end

        def self.from_files(key_path, cert_path)
          from_strings(File.read(key_path), File.read(cert_path))
        end

        def initialize(key, cert)
          @key = key
          @cert = cert
        end
      end
    end
  end
end
