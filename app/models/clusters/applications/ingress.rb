# frozen_string_literal: true

module Clusters
  module Applications
    # DEPRECATED for removal in %14.0
    # See https://gitlab.com/groups/gitlab-org/-/epics/4280
    class Ingress < ApplicationRecord
      VERSION = '1.40.2'
      INGRESS_CONTAINER_NAME = 'nginx-ingress-controller'

      self.table_name = 'clusters_applications_ingress'

      include ::Clusters::Concerns::ApplicationCore
      include ::Clusters::Concerns::ApplicationStatus
      include ::Clusters::Concerns::ApplicationVersion
      include ::Clusters::Concerns::ApplicationData
      include AfterCommitQueue
      include UsageStatistics
      include IgnorableColumns

      default_value_for :ingress_type, :nginx
      default_value_for :version, VERSION

      ignore_column :modsecurity_enabled, remove_with: '14.2', remove_after: '2021-07-22'
      ignore_column :modsecurity_mode, remove_with: '14.2', remove_after: '2021-07-22'

      enum ingress_type: {
        nginx: 1
      }

      FETCH_IP_ADDRESS_DELAY = 30.seconds

      state_machine :status do
        after_transition any => [:installed] do |application|
          application.run_after_commit do
            ClusterWaitForIngressIpAddressWorker.perform_in(
              FETCH_IP_ADDRESS_DELAY, application.name, application.id)
          end
        end
      end

      def chart
        "#{name}/nginx-ingress"
      end

      def repository
        'https://gitlab-org.gitlab.io/cluster-integration/helm-stable-archive'
      end

      def values
        content_values.to_yaml
      end

      def allowed_to_uninstall?
        external_ip_or_hostname? && !application_jupyter_installed?
      end

      def install_command
        helm_command_module::InstallCommand.new(
          name: name,
          repository: repository,
          version: VERSION,
          rbac: cluster.platform_kubernetes_rbac?,
          chart: chart,
          files: files
        )
      end

      def external_ip_or_hostname?
        external_ip.present? || external_hostname.present?
      end

      def schedule_status_update
        return unless installed?
        return if external_ip
        return if external_hostname

        ClusterWaitForIngressIpAddressWorker.perform_async(name, id)
      end

      def ingress_service
        cluster.kubeclient.get_service("ingress-#{INGRESS_CONTAINER_NAME}", Gitlab::Kubernetes::Helm::NAMESPACE)
      end

      private

      def content_values
        YAML.load_file(chart_values_file)
      end

      def application_jupyter_installed?
        cluster.application_jupyter&.installed?
      end
    end
  end
end
