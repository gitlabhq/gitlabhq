# frozen_string_literal: true

module Clusters
  module Applications
    class CertManager < ApplicationRecord
      VERSION = 'v0.5.2'.freeze

      self.table_name = 'clusters_applications_cert_managers'

      include ::Clusters::Concerns::ApplicationCore
      include ::Clusters::Concerns::ApplicationStatus
      include ::Clusters::Concerns::ApplicationVersion
      include ::Clusters::Concerns::ApplicationData

      default_value_for :version, VERSION

      default_value_for :email do |cert_manager|
        cert_manager.cluster&.user&.email
      end

      validates :email, presence: true

      def chart
        'stable/cert-manager'
      end

      def install_command
        Gitlab::Kubernetes::Helm::InstallCommand.new(
          name: 'certmanager',
          version: VERSION,
          rbac: cluster.platform_kubernetes_rbac?,
          chart: chart,
          files: files.merge(cluster_issuer_file),
          postinstall: post_install_script
        )
      end

      def uninstall_command
        Gitlab::Kubernetes::Helm::DeleteCommand.new(
          name: 'certmanager',
          rbac: cluster.platform_kubernetes_rbac?,
          files: files,
          postdelete: post_delete_script
        )
      end

      private

      def post_install_script
        ["kubectl create -f /data/helm/certmanager/config/cluster_issuer.yaml"]
      end

      def post_delete_script
        [
          delete_private_key,
          delete_crd('certificates.certmanager.k8s.io'),
          delete_crd('clusterissuers.certmanager.k8s.io'),
          delete_crd('issuers.certmanager.k8s.io')
        ].compact
      end

      def private_key_name
        @private_key_name ||= cluster_issuer_content.dig('spec', 'acme', 'privateKeySecretRef', 'name')
      end

      def delete_private_key
        "kubectl delete secret -n #{Gitlab::Kubernetes::Helm::NAMESPACE} #{private_key_name} --ignore-not-found" if private_key_name.present?
      end

      def delete_crd(definition)
        "kubectl delete crd #{definition} --ignore-not-found"
      end

      def cluster_issuer_file
        {
          'cluster_issuer.yaml': cluster_issuer_yaml_content
        }
      end

      def cluster_issuer_yaml_content
        YAML.dump(cluster_issuer_content.deep_merge(cluster_issue_overlay))
      end

      def cluster_issuer_content
        YAML.safe_load(File.read(cluster_issuer_file_path))
      end

      def cluster_issue_overlay
        { "spec" => { "acme" => { "email" => self.email } } }
      end

      def cluster_issuer_file_path
        Rails.root.join('vendor', 'cert_manager', 'cluster_issuer.yaml')
      end
    end
  end
end
