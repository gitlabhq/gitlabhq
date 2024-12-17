# frozen_string_literal: true

require 'openssl'
require_relative 'memoize'

module Gitlab
  module SecretDetection
    module Utils
      module X509
        # Pulled from Gitlab.com source
        # Link: https://gitlab.com/gitlab-org/gitlab/-/blob/4713a798f997389f04e442db3d1d8349a39d5d46/lib/gitlab/x509/certificate.rb
        class Certificate
          CERT_REGEX = /-----BEGIN CERTIFICATE-----(?:.|\n)+?-----END CERTIFICATE-----/

          attr_reader :key, :cert, :ca_certs

          def self.default_cert_dir
            strong_memoize(:default_cert_dir) do
              ENV.fetch('SSL_CERT_DIR', OpenSSL::X509::DEFAULT_CERT_DIR)
            end
          end

          def self.default_cert_file
            strong_memoize(:default_cert_file) do
              ENV.fetch('SSL_CERT_FILE', OpenSSL::X509::DEFAULT_CERT_FILE)
            end
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

          # Returns all top-level, readable files in the default CA cert directory
          def self.ca_certs_paths
            cert_paths = Dir["#{default_cert_dir}/*"].select do |path|
              !File.directory?(path) && File.readable?(path)
            end
            cert_paths << default_cert_file if File.exist? default_cert_file
            cert_paths
          end

          # Returns a concatenated array of Strings, each being a PEM-coded CA certificate.
          def self.ca_certs_bundle
            strong_memoize(:ca_certs_bundle) do
              ca_certs_paths.flat_map do |cert_file|
                load_ca_certs_bundle(File.read(cert_file))
              end.uniq.join("\n")
            end
          end

          def self.reset_ca_certs_bundle
            clear_memoization(:ca_certs_bundle)
          end

          def self.reset_default_cert_paths
            clear_memoization(:default_cert_dir)
            clear_memoization(:default_cert_file)
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

          def key_string
            key.to_s
          end

          def cert_string
            cert.to_pem
          end

          def ca_certs_string
            ca_certs&.map(&:to_pem)&.join('\n') unless ca_certs.blank?
          end

          class << self
            include ::Gitlab::SecretDetection::Utils::StrongMemoize
          end
        end
      end
    end
  end
end
