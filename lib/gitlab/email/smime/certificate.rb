# frozen_string_literal: true

module Gitlab
  module Email
    module Smime
      class Certificate
        CERT_REGEX = /-----BEGIN CERTIFICATE-----(?:.|\n)+?-----END CERTIFICATE-----/.freeze

        attr_reader :key, :cert, :ca_certs

        def key_string
          key.to_s
        end

        def cert_string
          cert.to_pem
        end

        def ca_certs_string
          ca_certs.map(&:to_pem).join('\n') unless ca_certs.blank?
        end

        def self.from_strings(key_string, cert_string, ca_certs_string = nil)
          key = OpenSSL::PKey::RSA.new(key_string)
          cert = OpenSSL::X509::Certificate.new(cert_string)
          ca_certs = load_ca_certs_bundle(ca_certs_string)

          new(key, cert, ca_certs)
        end

        def self.from_files(key_path, cert_path, ca_certs_path = nil)
          ca_certs_string = File.read(ca_certs_path) if ca_certs_path

          from_strings(File.read(key_path), File.read(cert_path), ca_certs_string)
        end

        # Returns an array of OpenSSL::X509::Certificate objects, empty array if none found
        #
        # Ruby OpenSSL::X509::Certificate.new will only load the first
        # certificate if a bundle is presented, this allows to parse multiple certs
        # in the same file
        def self.load_ca_certs_bundle(ca_certs_string)
          return [] unless ca_certs_string

          ca_certs_string.scan(CERT_REGEX).map do |ca_cert_string|
            OpenSSL::X509::Certificate.new(ca_cert_string)
          end
        end

        def initialize(key, cert, ca_certs = nil)
          @key = key
          @cert = cert
          @ca_certs = ca_certs
        end
      end
    end
  end
end
