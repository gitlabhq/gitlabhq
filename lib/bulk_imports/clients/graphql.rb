# frozen_string_literal: true

module BulkImports
  module Clients
    class Graphql
      class HTTP < Graphlient::Adapters::HTTP::Adapter
        REQUEST_TIMEOUT = 60

        def execute(document:, operation_name: nil, variables: {}, context: {})
          response = ::Gitlab::HTTP.post(
            url,
            headers: headers,
            follow_redirects: false,
            timeout: REQUEST_TIMEOUT,
            body: {
              query: document.to_query_string,
              operationName: operation_name,
              variables: variables
            }.to_json
          )

          unless response.success?
            raise ::BulkImports::NetworkError.new(
              "Unsuccessful response #{response.code} from #{response.request.path.path}",
              response: response
            )
          end

          ::Gitlab::Json.parse(response.body)
        rescue *Gitlab::HTTP::HTTP_ERRORS, JSON::ParserError => e
          raise ::BulkImports::NetworkError, e
        end
      end
      private_constant :HTTP

      attr_reader :client

      delegate :query, :parse, to: :client

      def initialize(url: Gitlab::Saas.com_url, token: nil)
        @url = Gitlab::Utils.append_path(url, '/api/graphql')
        @token = token
        @client = Graphlient::Client.new(@url, options(http: HTTP))
      end

      def execute(...)
        client.execute(...)
      end

      def options(extra = {})
        return extra unless @token

        {
          headers: {
            'Content-Type' => 'application/json',
            'Authorization' => "Bearer #{@token}"
          }
        }.merge(extra)
      end
    end
  end
end
