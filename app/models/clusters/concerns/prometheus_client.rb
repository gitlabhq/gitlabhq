# frozen_string_literal: true

module Clusters
  module Concerns
    module PrometheusClient
      extend ActiveSupport::Concern

      included do
        include PrometheusAdapter

        def service_name
          'prometheus-prometheus-server'
        end

        def service_port
          80
        end

        def prometheus_client
          return unless kube_client

          proxy_url = kube_client.proxy_url('service', service_name, service_port, Gitlab::Kubernetes::Helm::NAMESPACE)

          # ensures headers containing auth data are appended to original k8s client options
          options = kube_client.rest_client.options
            .merge(prometheus_client_default_options)
            .merge(headers: kube_client.headers)
          Gitlab::PrometheusClient.new(proxy_url, options)
        rescue Kubeclient::HttpError, Errno::ECONNRESET, Errno::ECONNREFUSED, Errno::ENETUNREACH
          # If users have mistakenly set parameters or removed the depended clusters,
          # `proxy_url` could raise an exception because gitlab can not communicate with the cluster.
          # Since `PrometheusAdapter#can_query?` is eargely loaded on environement pages in gitlab,
          # we need to silence the exceptions
        end

        def configured?
          kube_client.present? && available?
        rescue Gitlab::UrlBlocker::BlockedUrlError
          false
        end

        private

        def kube_client
          cluster&.kubeclient&.core_client
        end
      end
    end
  end
end
