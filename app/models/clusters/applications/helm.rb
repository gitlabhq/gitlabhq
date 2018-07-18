require 'openssl'

module Clusters
  module Applications
    class Helm < ActiveRecord::Base
      self.table_name = 'clusters_applications_helm'

      attr_encrypted :ca_key,
        mode: :per_attribute_iv,
        key: Settings.attr_encrypted_db_key_base_truncated,
        algorithm: 'aes-256-cbc'

      include ::Clusters::Concerns::ApplicationCore
      include ::Clusters::Concerns::ApplicationStatus

      default_value_for :version, Gitlab::Kubernetes::Helm::HELM_VERSION

      before_create :create_keys_and_certs

      def create_keys_and_certs
        ca_cert = Gitlab::Kubernetes::Helm::Certificate.generate_root
        self.ca_key = ca_cert.key_string
        self.ca_cert = ca_cert.cert_string
      end

      def ca_cert_obj
        return unless has_ssl?
        Gitlab::Kubernetes::Helm::Certificate
          .from_strings(ca_key, ca_cert)
      end

      def issue_cert
        ca_cert_obj
          .issue
      end

      def set_initial_status
        return unless not_installable?

        self.status = 'installable' if cluster&.platform_kubernetes_active?
      end

      def install_command
        Gitlab::Kubernetes::Helm::InitCommand.new(
          name,
          ca_cert: ca_cert_obj
        )
      end

      def has_ssl?
        ca_key.present? && ca_cert.present?
      end
    end
  end
end
