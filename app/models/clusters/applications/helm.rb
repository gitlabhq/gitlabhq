require 'openssl'

module Clusters
  module Applications
    class Helm < ActiveRecord::Base
      self.table_name = 'clusters_applications_helm'

      include ::Clusters::Concerns::ApplicationCore
      include ::Clusters::Concerns::ApplicationStatus

      default_value_for :version, Gitlab::Kubernetes::Helm::HELM_VERSION

      after_initialize :create_keys_and_certs

      def create_keys_and_certs
        # CA
        ca_key = OpenSSL::PKey::RSA.new(4096)
        write_attribute(:ca_key, ca_key.to_s)
        public_key = ca_key.public_key

        subject = "/C=BE/O=Test/OU=Test/CN=Test"

        cert = OpenSSL::X509::Certificate.new
        cert.subject = cert.issuer = OpenSSL::X509::Name.parse(subject)
        cert.not_before = Time.now
        cert.not_after = Time.now + 365 * 24 * 60 * 60
        cert.public_key = public_key
        cert.serial = 0x0
        cert.version = 2

        ef = OpenSSL::X509::ExtensionFactory.new
        ef.subject_certificate = cert
        ef.issuer_certificate = cert
        cert.extensions = [
          ef.create_extension("basicConstraints","CA:TRUE", true),
          ef.create_extension("subjectKeyIdentifier", "hash"),
          # ef.create_extension("keyUsage", "cRLSign,keyCertSign", true),
        ]
        cert.add_extension ef.create_extension("authorityKeyIdentifier",
                                               "keyid:always,issuer:always")

        cert.sign ca_key, OpenSSL::Digest::SHA256.new
        write_attribute(:ca_cert, cert.to_pem)

        # Client Key
        client_key = OpenSSL::PKey::RSA.new(4096)
        write_attribute(:client_key, client_key.to_s)
        public_key = client_key.public_key

        subject = "/C=BE/O=Test/OU=Test/CN=Test"

        cert = OpenSSL::X509::Certificate.new
        cert.subject = cert.issuer = OpenSSL::X509::Name.parse(subject)
        cert.not_before = Time.now
        cert.not_after = Time.now + 365 * 24 * 60 * 60
        cert.public_key = public_key
        cert.serial = 0x0
        cert.version = 2

        ef = OpenSSL::X509::ExtensionFactory.new
        ef.subject_certificate = cert
        ef.issuer_certificate = cert
        cert.extensions = [
          ef.create_extension("basicConstraints","CA:FALSE", true),
          ef.create_extension("subjectKeyIdentifier", "hash"),
          # ef.create_extension("keyUsage", "cRLSign,keyCertSign", true),
        ]
        cert.add_extension ef.create_extension("authorityKeyIdentifier",
                                               "keyid:always,issuer:always")

        cert.sign ca_key, OpenSSL::Digest::SHA256.new

        write_attribute(:client_cert, cert.to_pem)

        # Server Key
        server_key = OpenSSL::PKey::RSA.new(4096)
        write_attribute(:server_key, server_key.to_s)
        public_key = server_key.public_key

        subject = "/C=BE/O=Test/OU=Test/CN=Test"

        cert = OpenSSL::X509::Certificate.new
        cert.subject = cert.issuer = OpenSSL::X509::Name.parse(subject)
        cert.not_before = Time.now
        cert.not_after = Time.now + 365 * 24 * 60 * 60
        cert.public_key = public_key
        cert.serial = 0x0
        cert.version = 2

        ef = OpenSSL::X509::ExtensionFactory.new
        ef.subject_certificate = cert
        ef.issuer_certificate = cert
        cert.extensions = [
          ef.create_extension("basicConstraints","CA:FALSE", true),
          ef.create_extension("subjectKeyIdentifier", "hash"),
          # ef.create_extension("keyUsage", "cRLSign,keyCertSign", true),
        ]
        cert.add_extension ef.create_extension("authorityKeyIdentifier",
                                               "keyid:always,issuer:always")

        cert.sign ca_key, OpenSSL::Digest::SHA256.new

        write_attribute(:server_cert, cert.to_pem)
      end

      def set_initial_status
        return unless not_installable?

        self.status = 'installable' if cluster&.platform_kubernetes_active?
      end

      def install_command
        Gitlab::Kubernetes::Helm::InitCommand.new(name)
      end
    end
  end
end
