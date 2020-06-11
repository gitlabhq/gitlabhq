# frozen_string_literal: true

require 'openssl'

module Clusters
  module Applications
    class Helm < ApplicationRecord
      self.table_name = 'clusters_applications_helm'

      attr_encrypted :ca_key,
        mode: :per_attribute_iv,
        key: Settings.attr_encrypted_db_key_base_truncated,
        algorithm: 'aes-256-cbc'

      include ::Clusters::Concerns::ApplicationCore
      include ::Clusters::Concerns::ApplicationStatus
      include ::Gitlab::Utils::StrongMemoize

      default_value_for :version, Gitlab::Kubernetes::Helm::HELM_VERSION

      before_create :create_keys_and_certs

      def issue_client_cert
        ca_cert_obj.issue
      end

      def set_initial_status
        return unless not_installable?

        self.status = status_states[:installable] if cluster&.platform_kubernetes_active?
      end

      # It can only be uninstalled if there are no other applications installed
      # or with intermitent installation statuses in the database.
      def allowed_to_uninstall?
        strong_memoize(:allowed_to_uninstall) do
          applications = nil

          Clusters::Cluster::APPLICATIONS.each do |application_name, klass|
            next if application_name == 'helm'

            extra_apps = Clusters::Applications::Helm.where('EXISTS (?)', klass.select(1).where(cluster_id: cluster_id))

            applications = applications ? applications.or(extra_apps) : extra_apps
          end

          !applications.exists?
        end
      end

      def install_command
        Gitlab::Kubernetes::Helm::InitCommand.new(
          name: name,
          files: files,
          rbac: cluster.platform_kubernetes_rbac?,
          local_tiller_enabled: cluster.local_tiller_enabled?
        )
      end

      def uninstall_command
        Gitlab::Kubernetes::Helm::ResetCommand.new(
          name: name,
          files: files,
          rbac: cluster.platform_kubernetes_rbac?,
          local_tiller_enabled: cluster.local_tiller_enabled?
        )
      end

      def has_ssl?
        ca_key.present? && ca_cert.present?
      end

      def post_uninstall
        cluster.kubeclient.delete_namespace(Gitlab::Kubernetes::Helm::NAMESPACE)
      rescue Kubeclient::ResourceNotFoundError
        # we actually don't care if the namespace is not present
        # since we want to delete it anyway.
      end

      private

      def files
        {
          'ca.pem': ca_cert,
          'cert.pem': tiller_cert.cert_string,
          'key.pem': tiller_cert.key_string
        }
      end

      def create_keys_and_certs
        ca_cert = Gitlab::Kubernetes::Helm::Certificate.generate_root
        self.ca_key = ca_cert.key_string
        self.ca_cert = ca_cert.cert_string
      end

      def tiller_cert
        @tiller_cert ||= ca_cert_obj.issue(expires_in: Gitlab::Kubernetes::Helm::Certificate::INFINITE_EXPIRY)
      end

      def ca_cert_obj
        return unless has_ssl?

        Gitlab::Kubernetes::Helm::Certificate
          .from_strings(ca_key, ca_cert)
      end
    end
  end
end
