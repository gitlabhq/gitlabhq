# frozen_string_literal: true

module ActiveContext
  module Databases
    module Elasticsearch
      class Client
        include ActiveContext::Databases::Concerns::Client

        delegate :bulk, to: :client

        OPEN_TIMEOUT = 5
        NO_RETRY = 0

        def initialize(options)
          @options = options
        end

        def search(collection:, query:)
          raise ArgumentError, "Expected Query object, you used #{query.class}" unless query.is_a?(ActiveContext::Query)

          es_query = Processor.transform(query)
          res = client.search(index: collection, body: es_query)
          QueryResult.new(res)
        end

        def client
          ::Elasticsearch::Client.new(elasticsearch_config)
        end

        private

        def elasticsearch_config
          {
            adapter: :net_http,
            urls: options[:url],
            transport_options: {
              request: {
                timeout: options[:client_request_timeout],
                open_timeout: OPEN_TIMEOUT
              }
            },
            randomize_hosts: true,
            retry_on_failure: options[:retry_on_failure] || NO_RETRY,
            log: options[:debug],
            debug: options[:debug]
          }.compact
        end
      end
    end
  end
end
