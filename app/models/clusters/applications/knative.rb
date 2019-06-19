# frozen_string_literal: true

module Clusters
  module Applications
    class Knative < ApplicationRecord
      VERSION = '0.6.0'.freeze
      REPOSITORY = 'https://storage.googleapis.com/triggermesh-charts'.freeze
      METRICS_CONFIG = 'https://storage.googleapis.com/triggermesh-charts/istio-metrics.yaml'.freeze
      FETCH_IP_ADDRESS_DELAY = 30.seconds

      self.table_name = 'clusters_applications_knative'

      include ::Clusters::Concerns::ApplicationCore
      include ::Clusters::Concerns::ApplicationStatus
      include ::Clusters::Concerns::ApplicationVersion
      include ::Clusters::Concerns::ApplicationData
      include AfterCommitQueue

      def set_initial_status
        return unless not_installable?
        return unless verify_cluster?

        self.status = 'installable'
      end

      state_machine :status do
        after_transition any => [:installed] do |application|
          application.run_after_commit do
            ClusterWaitForIngressIpAddressWorker.perform_in(
              FETCH_IP_ADDRESS_DELAY, application.name, application.id)
          end
        end
      end

      default_value_for :version, VERSION

      validates :hostname, presence: true, hostname: true

      scope :for_cluster, -> (cluster) { where(cluster: cluster) }

      def chart
        'knative/knative'
      end

      def values
        { "domain" => hostname }.to_yaml
      end

      # Handled in a new issue:
      # https://gitlab.com/gitlab-org/gitlab-ce/issues/59369
      def allowed_to_uninstall?
        false
      end

      def install_command
        Gitlab::Kubernetes::Helm::InstallCommand.new(
          name: name,
          version: VERSION,
          rbac: cluster.platform_kubernetes_rbac?,
          chart: chart,
          files: files,
          repository: REPOSITORY,
          postinstall: install_knative_metrics
        )
      end

      def schedule_status_update
        return unless installed?
        return if external_ip
        return if external_hostname

        ClusterWaitForIngressIpAddressWorker.perform_async(name, id)
      end

      def ingress_service
        cluster.kubeclient.get_service('istio-ingressgateway', 'istio-system')
      end

      private

      def install_knative_metrics
        ["kubectl apply -f #{METRICS_CONFIG}"] if cluster.application_prometheus_available?
      end

      def verify_cluster?
        cluster&.application_helm_available? && cluster&.platform_kubernetes_rbac?
      end
    end
  end
end
