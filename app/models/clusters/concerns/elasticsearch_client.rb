# frozen_string_literal: true

module Clusters
  module Concerns
    module ElasticsearchClient
      include ::Gitlab::Utils::StrongMemoize

      ELASTICSEARCH_PORT = 9200
      ELASTICSEARCH_NAMESPACE = 'gitlab-managed-apps'

      def elasticsearch_client(timeout: nil)
        strong_memoize(:elasticsearch_client) do
          kube_client = cluster&.kubeclient&.core_client
          next unless kube_client

          proxy_url = kube_client.proxy_url('service', service_name, ELASTICSEARCH_PORT, ELASTICSEARCH_NAMESPACE)

          Elasticsearch::Client.new(url: proxy_url) do |faraday|
            # ensures headers containing auth data are appended to original client options
            faraday.headers.merge!(kube_client.headers)
            # ensure TLS certs are properly verified
            faraday.ssl[:verify] = kube_client.ssl_options[:verify_ssl]
            faraday.ssl[:cert_store] = kube_client.ssl_options[:cert_store]
            faraday.options.timeout = timeout unless timeout.nil?
          end

        rescue Kubeclient::HttpError => error
          # If users have mistakenly set parameters or removed the depended clusters,
          # `proxy_url` could raise an exception because gitlab can not communicate with the cluster.
          # We check for a nil client in downstream use and behaviour is equivalent to an empty state
          log_exception(error, :failed_to_create_elasticsearch_client)

          nil
        end
      end
    end
  end
end
