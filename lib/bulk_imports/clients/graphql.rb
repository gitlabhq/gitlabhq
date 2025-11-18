# frozen_string_literal: true

module BulkImports
  module Clients
    class Graphql
      REQUEST_TIMEOUT = 60

      attr_reader :url

      def initialize(url: Gitlab.com_url, token: nil)
        @url = Gitlab::Utils.append_path(url, '/api/graphql')
        @token = token
      end

      def execute(query:, variables: {})
        response = Import::Clients::HTTP.post(
          url,
          headers: headers,
          follow_redirects: false,
          timeout: REQUEST_TIMEOUT,
          body: {
            query: query,
            operationName: nil,
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

      def headers
        {
          'Content-Type' => 'application/json',
          'Authorization' => "Bearer #{@token}"
        }
      end
    end
  end
end
