require 'openssl'

module Clusters
  module Applications
    class Helm < ActiveRecord::Base
      self.table_name = 'clusters_applications_helm'

      include ::Clusters::Concerns::ApplicationCore
      include ::Clusters::Concerns::ApplicationStatus

      default_value_for :version, Gitlab::Kubernetes::Helm::HELM_VERSION

      before_create :create_keys_and_certs

      def create_keys_and_certs
        # CA
        ca_key = OpenSSL::PKey::RSA.new(4096)
        write_attribute(:ca_key, ca_key.to_s)
        public_key = ca_key.public_key

        subject = "/C=AU"

        ca_cert = OpenSSL::X509::Certificate.new
        ca_cert.subject = ca_cert.issuer = OpenSSL::X509::Name.parse(subject)
        ca_cert.not_before = Time.now
        ca_cert.not_after = Time.now + 365 * 24 * 60 * 60
        ca_cert.public_key = public_key
        ca_cert.serial = 0x0
        ca_cert.version = 2

        extension_factory = OpenSSL::X509::ExtensionFactory.new
        extension_factory.subject_certificate = ca_cert
        extension_factory.issuer_certificate = ca_cert
        ca_cert.add_extension(extension_factory.create_extension('subjectKeyIdentifier', 'hash'))
        ca_cert.add_extension(extension_factory.create_extension('basicConstraints', 'CA:TRUE', true))
        ca_cert.add_extension(extension_factory.create_extension('keyUsage', 'cRLSign,keyCertSign', true))

        ca_cert.sign ca_key, OpenSSL::Digest::SHA256.new
        write_attribute(:ca_cert, ca_cert.to_pem)

        # Client Key
        client_key = OpenSSL::PKey::RSA.new(4096)
        write_attribute(:client_key, client_key.to_s)
        public_key = client_key.public_key

        cert = OpenSSL::X509::Certificate.new
        cert.subject = OpenSSL::X509::Name.parse(subject)
        cert.issuer = ca_cert.subject
        cert.not_before = Time.now
        cert.not_after = Time.now + 365 * 24 * 60 * 60
        cert.public_key = public_key
        cert.serial = 0x0
        cert.version = 2

        cert.sign ca_key, OpenSSL::Digest::SHA256.new

        write_attribute(:client_cert, cert.to_pem)

        # Server Key
        server_key = OpenSSL::PKey::RSA.new(4096)
        write_attribute(:server_key, server_key.to_s)
        public_key = server_key.public_key

        cert = OpenSSL::X509::Certificate.new
        cert.subject = OpenSSL::X509::Name.parse(subject)
        cert.issuer = ca_cert.subject
        cert.not_before = Time.now
        cert.not_after = Time.now + 365 * 24 * 60 * 60
        cert.public_key = public_key
        cert.serial = 0x0
        cert.version = 2

        cert.sign ca_key, OpenSSL::Digest::SHA256.new

        write_attribute(:server_cert, cert.to_pem)

      end

      def set_initial_status
        return unless not_installable?

        self.status = 'installable' if cluster&.platform_kubernetes_active?
      end

      def extra_env
        {
          "CA_CERT" => Base64.encode64(ca_cert),
          "TILLER_CERT" => Base64.encode64(server_cert),
          "TILLER_KEY" => Base64.encode64(server_key),
        }
      end

      def install_command
        Gitlab::Kubernetes::Helm::InitCommand.new(
          name,
          extra_env: extra_env,
        )
      end
    end
  end
end
