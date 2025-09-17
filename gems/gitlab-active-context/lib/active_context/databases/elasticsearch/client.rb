# frozen_string_literal: true

module ActiveContext
  module Databases
    module Elasticsearch
      class Client
        include ActiveContext::Databases::Concerns::Client

        delegate :bulk, :delete_by_query, to: :client

        OPEN_TIMEOUT = 5
        NO_RETRY = 0
        DEFAULT_ADAPTER = :typhoeus

        def initialize(options)
          @options = options
        end

        def search(user:, collection:, query:)
          es_query = Processor.transform(collection: collection, node: query, user: user)
          result = client.search(index: collection.collection_name, body: es_query)

          QueryResult.new(result: result, collection: collection, user: user).authorized_results
        end

        def client
          ::Elasticsearch::Client.new(elasticsearch_config)
        end

        private

        def elasticsearch_config
          {
            adapter: options[:client_adapter] || DEFAULT_ADAPTER,
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
