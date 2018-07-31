module Clusters
  module Applications
    class Prometheus < ActiveRecord::Base
      include PrometheusAdapter

      VERSION = '6.7.3'.freeze

      self.table_name = 'clusters_applications_prometheus'

      include ::Clusters::Concerns::ApplicationCore
      include ::Clusters::Concerns::ApplicationStatus
      include ::Clusters::Concerns::ApplicationData

      default_value_for :version, VERSION

      state_machine :status do
        after_transition any => [:installed] do |application|
          application.cluster.projects.each do |project|
            project.find_or_initialize_service('prometheus').update(active: true)
          end
        end
      end

      def ready_status
        [:installed]
      end

      def ready?
        ready_status.include?(status_name)
      end

      def chart
        'stable/prometheus'
      end

      def service_name
        'prometheus-prometheus-server'
      end

      def service_port
        80
      end

      def install_command
        Gitlab::Kubernetes::Helm::InstallCommand.new(
          name,
          chart: chart,
          version: version,
          values: values
        )
      end

      def prometheus_client
        return unless kube_client

        proxy_url = kube_client.proxy_url('service', service_name, service_port, Gitlab::Kubernetes::Helm::NAMESPACE)

        # ensures headers containing auth data are appended to original k8s client options
        options = kube_client.rest_client.options.merge(headers: kube_client.headers)
        RestClient::Resource.new(proxy_url, options)
      rescue Kubeclient::HttpError
        # If users have mistakenly set parameters or removed the depended clusters,
        # `proxy_url` could raise an exception because gitlab can not communicate with the cluster.
        # Since `PrometheusAdapter#can_query?` is eargely loaded on environement pages in gitlab,
        # we need to silence the exceptions
      end

      private

      def kube_client
        cluster&.kubeclient
      end
    end
  end
end
