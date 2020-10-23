# frozen_string_literal: true

module BulkImports
  module Clients
    class Graphql
      attr_reader :client

      delegate :query, :parse, :execute, to: :client

      def initialize(url: Gitlab::COM_URL, token: nil)
        @url = Gitlab::Utils.append_path(url, '/api/graphql')
        @token = token
        @client = Graphlient::Client.new(
          @url,
          request_headers
        )
      end

      def request_headers
        return {} unless @token

        {
          headers: {
            'Content-Type' => 'application/json',
            'Authorization' => "Bearer #{@token}"
          }
        }
      end
    end
  end
end
