# frozen_string_literal: true

module Clusters
  module Applications
    # DEPRECATED for removal in %14.0
    # See https://gitlab.com/groups/gitlab-org/-/epics/4280
    class CertManager < ApplicationRecord
      VERSION = 'v0.10.1'
      CRD_VERSION = '0.10'

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
        'certmanager/cert-manager'
      end

      def repository
        'https://charts.jetstack.io'
      end

      def install_command
        helm_command_module::InstallCommand.new(
          name: 'certmanager',
          repository: repository,
          version: VERSION,
          rbac: cluster.platform_kubernetes_rbac?,
          chart: chart,
          files: files.merge(cluster_issuer_file),
          preinstall: pre_install_script,
          postinstall: post_install_script
        )
      end

      def uninstall_command
        helm_command_module::DeleteCommand.new(
          name: 'certmanager',
          rbac: cluster.platform_kubernetes_rbac?,
          files: files,
          postdelete: post_delete_script
        )
      end

      private

      def pre_install_script
        [
          apply_file("https://raw.githubusercontent.com/jetstack/cert-manager/release-#{CRD_VERSION}/deploy/manifests/00-crds.yaml"),
          "kubectl label --overwrite namespace #{Gitlab::Kubernetes::Helm::NAMESPACE} certmanager.k8s.io/disable-validation=true"
        ]
      end

      def post_install_script
        [retry_command(apply_file('/data/helm/certmanager/config/cluster_issuer.yaml'))]
      end

      def retry_command(command)
        Gitlab::Kubernetes::PodCmd.retry_command(command, times: 90)
      end

      def post_delete_script
        [
          delete_private_key,
          delete_crd('certificates.certmanager.k8s.io'),
          delete_crd('certificaterequests.certmanager.k8s.io'),
          delete_crd('challenges.certmanager.k8s.io'),
          delete_crd('clusterissuers.certmanager.k8s.io'),
          delete_crd('issuers.certmanager.k8s.io'),
          delete_crd('orders.certmanager.k8s.io')
        ].compact
      end

      def private_key_name
        @private_key_name ||= cluster_issuer_content.dig('spec', 'acme', 'privateKeySecretRef', 'name')
      end

      def delete_private_key
        return unless private_key_name.present?

        args = %W(secret -n #{Gitlab::Kubernetes::Helm::NAMESPACE} #{private_key_name} --ignore-not-found)

        Gitlab::Kubernetes::KubectlCmd.delete(*args)
      end

      def delete_crd(definition)
        Gitlab::Kubernetes::KubectlCmd.delete("crd", definition, "--ignore-not-found")
      end

      def apply_file(filename)
        Gitlab::Kubernetes::KubectlCmd.apply_file(filename)
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
