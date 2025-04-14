# frozen_string_literal: true

require 'opensearch'
require 'faraday_middleware/aws_sigv4'

module ActiveContext
  module Databases
    module Opensearch
      class Client
        include ActiveContext::Databases::Concerns::Client

        delegate :bulk, :delete_by_query, to: :client

        OPEN_TIMEOUT = 5
        NO_RETRY = 0

        def initialize(options)
          @options = options
        end

        def search(user:, collection:, query:)
          es_query = Processor.transform(collection, query)
          result = client.search(index: collection.collection_name, body: es_query)

          QueryResult.new(result: result, collection: collection, user: user).authorized_results
        end

        def client
          ::OpenSearch::Client.new(opensearch_config) do |fmid|
            next unless options[:aws]

            fmid.request(
              :aws_sigv4,
              credentials_provider: aws_credentials,
              service: 'es',
              region: options[:aws_region]
            )
          end
        end

        def aws_credentials
          static_credentials = ::Aws::Credentials.new(options[:aws_access_key], options[:aws_secret_access_key])

          return static_credentials if static_credentials&.set?

          aws_credential_provider = ::Aws::CredentialProviderChain.new.resolve
          aws_credential_provider if aws_credential_provider&.set?
        end

        private

        def opensearch_config
          {
            adapter: :typhoeus,
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
