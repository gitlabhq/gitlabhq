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

      # We will implement this in future MRs.
      # Need to reverse postinstall step
      def allowed_to_uninstall?
        false
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

      private

      def post_install_script
        ["kubectl create -f /data/helm/certmanager/config/cluster_issuer.yaml"]
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
