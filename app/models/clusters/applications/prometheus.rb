# frozen_string_literal: true

module Clusters
  module Applications
    class Prometheus < ApplicationRecord
      include ::Clusters::Concerns::PrometheusClient

      VERSION = '10.4.1'

      self.table_name = 'clusters_applications_prometheus'

      include ::Clusters::Concerns::ApplicationCore
      include ::Clusters::Concerns::ApplicationStatus
      include ::Clusters::Concerns::ApplicationVersion
      include ::Clusters::Concerns::ApplicationData
      include AfterCommitQueue

      default_value_for :version, VERSION

      scope :preload_cluster_platform, -> { preload(cluster: [:platform_kubernetes]) }
      scope :with_clusters_with_cilium, -> { joins(:cluster).merge(Clusters::Cluster.with_available_cilium) }

      attr_encrypted :alert_manager_token,
        mode: :per_attribute_iv,
        key: Settings.attr_encrypted_db_key_base_32,
        algorithm: 'aes-256-gcm'

      default_value_for(:alert_manager_token) { SecureRandom.hex }

      after_destroy do
        cluster.find_or_build_integration_prometheus.destroy
      end

      state_machine :status do
        after_transition any => [:installed, :externally_installed] do |application|
          application.cluster.find_or_build_integration_prometheus.update(enabled: true, alert_manager_token: application.alert_manager_token)
        end

        after_transition any => :updating do |application|
          application.update(last_update_started_at: Time.current)
        end
      end

      def managed_prometheus?
        !externally_installed? && !uninstalled?
      end

      def updated_since?(timestamp)
        last_update_started_at &&
          last_update_started_at > timestamp &&
          !update_errored?
      end

      def chart
        "#{name}/prometheus"
      end

      def repository
        'https://gitlab-org.gitlab.io/cluster-integration/helm-stable-archive'
      end

      def install_command
        helm_command_module::InstallCommand.new(
          name: name,
          repository: repository,
          version: VERSION,
          rbac: cluster.platform_kubernetes_rbac?,
          chart: chart,
          files: files,
          postinstall: install_knative_metrics
        )
      end

      # Deprecated, to be removed in %14.0 as part of https://gitlab.com/groups/gitlab-org/-/epics/4280
      def patch_command(values)
        helm_command_module::PatchCommand.new(
          name: name,
          repository: repository,
          version: version,
          rbac: cluster.platform_kubernetes_rbac?,
          chart: chart,
          files: files_with_replaced_values(values)
        )
      end

      def uninstall_command
        helm_command_module::DeleteCommand.new(
          name: name,
          rbac: cluster.platform_kubernetes_rbac?,
          files: files,
          predelete: delete_knative_istio_metrics
        )
      end

      # Returns a copy of files where the values of 'values.yaml'
      # are replaced by the argument.
      #
      # See #values for the data format required
      def files_with_replaced_values(replaced_values)
        files.merge('values.yaml': replaced_values)
      end

      private

      def install_knative_metrics
        return [] unless cluster.application_knative_available?

        [Gitlab::Kubernetes::KubectlCmd.apply_file(Clusters::Applications::Knative::METRICS_CONFIG)]
      end

      def delete_knative_istio_metrics
        return [] unless cluster.application_knative_available?

        [
          Gitlab::Kubernetes::KubectlCmd.delete(
            "-f", Clusters::Applications::Knative::METRICS_CONFIG,
            "--ignore-not-found"
          )
        ]
      end
    end
  end
end
