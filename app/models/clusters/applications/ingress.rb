# frozen_string_literal: true

module Clusters
  module Applications
    class Ingress < ApplicationRecord
      VERSION = '1.1.2'.freeze

      self.table_name = 'clusters_applications_ingress'

      include ::Clusters::Concerns::ApplicationCore
      include ::Clusters::Concerns::ApplicationStatus
      include ::Clusters::Concerns::ApplicationVersion
      include ::Clusters::Concerns::ApplicationData
      include AfterCommitQueue

      default_value_for :ingress_type, :nginx
      default_value_for :version, VERSION

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
        'stable/nginx-ingress'
      end

      # We will implement this in future MRs.
      # Basically we need to check all dependent applications are not installed
      # first.
      def allowed_to_uninstall?
        false
      end

      def install_command
        Gitlab::Kubernetes::Helm::InstallCommand.new(
          name: name,
          version: VERSION,
          rbac: cluster.platform_kubernetes_rbac?,
          chart: chart,
          files: files
        )
      end

      def schedule_status_update
        return unless installed?
        return if external_ip
        return if external_hostname

        ClusterWaitForIngressIpAddressWorker.perform_async(name, id)
      end

      def ingress_service
        cluster.kubeclient.get_service('ingress-nginx-ingress-controller', Gitlab::Kubernetes::Helm::NAMESPACE)
      end
    end
  end
end
