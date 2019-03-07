# frozen_string_literal: true

module Clusters
  module Applications
    class Knative < ActiveRecord::Base
      VERSION = '0.2.2'.freeze
      REPOSITORY = 'https://storage.googleapis.com/triggermesh-charts'.freeze
      METRICS_CONFIG = 'https://storage.googleapis.com/triggermesh-charts/istio-metrics.yaml'.freeze
      FETCH_IP_ADDRESS_DELAY = 30.seconds

      self.table_name = 'clusters_applications_knative'

      include ::Clusters::Concerns::ApplicationCore
      include ::Clusters::Concerns::ApplicationStatus
      include ::Clusters::Concerns::ApplicationVersion
      include ::Clusters::Concerns::ApplicationData
      include AfterCommitQueue
      include ReactiveCaching

      self.reactive_cache_key = ->(knative) { [knative.class.model_name.singular, knative.id] }

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

      after_save :clear_reactive_cache!

      def chart
        'knative/knative'
      end

      def values
        { "domain" => hostname }.to_yaml
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

      def client
        cluster.kubeclient.knative_client
      end

      def services
        with_reactive_cache do |data|
          data[:services]
        end
      end

      def calculate_reactive_cache
        { services: read_services, pods: read_pods }
      end

      def ingress_service
        cluster.kubeclient.get_service('knative-ingressgateway', 'istio-system')
      end

      def services_for(ns: namespace)
        return [] unless services
        return [] unless ns

        services.select do |service|
          service.dig('metadata', 'namespace') == ns
        end
      end

      def service_pod_details(ns, service)
        with_reactive_cache do |data|
          data[:pods].select { |pod| filter_pods(pod, ns, service) }
        end
      end

      private

      def read_pods
        cluster.kubeclient.core_client.get_pods.as_json
      end

      def filter_pods(pod, namespace, service)
        pod["metadata"]["namespace"] == namespace && pod["metadata"]["labels"]["serving.knative.dev/service"] == service
      end

      def read_services
        client.get_services.as_json
      rescue Kubeclient::ResourceNotFoundError
        []
      end

      def install_knative_metrics
        ["kubectl apply -f #{METRICS_CONFIG}"] if cluster.application_prometheus_available?
      end

      def verify_cluster?
        cluster&.application_helm_available? && cluster&.platform_kubernetes_rbac?
      end
    end
  end
end
