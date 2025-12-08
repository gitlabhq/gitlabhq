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
          es_query = add_source_fields(es_query, collection)

          result = client.search(index: collection.collection_name, body: es_query)

          QueryResult.new(result: result, collection: collection, user: user).authorized_results
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

        # In ES 9.2+, vector fields are excluded from _source by default.
        # We explicitly include them here so that MarkRepositoryAsReadyEventWorker
        # can verify embeddings are populated. The '*' wildcard includes all
        # non-vector fields, and we add vector fields explicitly.
        def add_source_fields(es_query, collection)
          es_query.merge(_source: { includes: ['*'] + collection.current_embedding_fields })
        end
      end
    end
  end
end
