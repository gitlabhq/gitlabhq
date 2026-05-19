# frozen_string_literal: true

module ActiveContext
  module Databases
    module Elasticsearch
      class Client
        include ActiveContext::Databases::Concerns::ElasticClient

        delegate :bulk, :delete_by_query, to: :client

        OPEN_TIMEOUT = 5
        NO_RETRY = 0
        DEFAULT_ADAPTER = :typhoeus

        def initialize(options)
          @options = options
        end

        def search(user:, collection:, query:, source_fields: nil)
          es_query = Processor.transform(collection: collection, node: query, user: user)
          es_query = add_source_fields(es_query, source_fields)

          query_result = log_search(collection: collection) do
            result = client.search(index: collection.collection_name, body: es_query)
            QueryResult.new(result: result, collection: collection, user: user)
          end

          query_result.authorized_results
        end

        def client
          ::Elasticsearch::Client.new(elasticsearch_config)
        end

        private

        def elasticsearch_config
          {
            adapter: options[:client_adapter]&.to_sym || DEFAULT_ADAPTER,
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
