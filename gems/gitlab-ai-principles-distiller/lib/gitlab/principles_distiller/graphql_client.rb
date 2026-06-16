# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'

module Gitlab
  module PrinciplesDistiller
    # Minimal GraphQL client for the GitLab API. Returns the parsed `data`
    # payload, or raises `GraphqlClient::Error` on transport failure,
    # non-2xx, or a non-empty `errors` array. Error policy (warn vs abort)
    # is the caller's choice.
    class GraphqlClient
      Error = Class.new(StandardError)

      DEFAULT_READ_TIMEOUT = 60

      def initialize(host:, token:, read_timeout: DEFAULT_READ_TIMEOUT)
        @host = host.chomp('/')
        @token = token
        @read_timeout = read_timeout
      end

      def query(query, variables = {})
        response = post_graphql(query, variables)

        unless response.is_a?(Net::HTTPSuccess)
          raise Error, "GraphQL HTTP #{response.code}: #{response.body.to_s.slice(0, 500)}"
        end

        body = JSON.parse(response.body)
        if body['errors']
          messages = body['errors'].map { |e| e['message'] }
          raise Error, "GraphQL errors: #{messages.join('; ')}"
        end

        body['data']
      end

      private

      def post_graphql(query, variables)
        uri = URI("#{@host}/api/graphql")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == 'https'
        http.read_timeout = @read_timeout

        request = Net::HTTP::Post.new(uri)
        request['Authorization'] = "Bearer #{@token}"
        request['Content-Type'] = 'application/json'
        request.body = { query: query, variables: variables }.to_json

        http.request(request)
      end
    end
  end
end
