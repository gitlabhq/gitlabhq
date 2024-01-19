# frozen_string_literal: true

module Gitlab
  module BeyondIdentity
    class Client
      API_URL = "https://api.byndid.com/key-mgmt/v0/gpg/key/authorization/git-commit-signing"

      Error = Class.new(StandardError)

      attr_reader :integration

      def initialize(integration)
        raise Error, 'integration is not activated' unless integration.activated?

        @integration = integration
      end

      def execute(params)
        options = { headers: headers, query: params }
        response = Gitlab::HTTP.get(API_URL, options)
        body = Gitlab::Json.parse(response.body) || {}

        raise Error, body.dig('error', 'message') unless response.success?
        raise Error, "authorization denied: #{body['message']}" unless body['authorized']

        body
      rescue JSON::ParserError
        raise Error, 'invalid response format'
      end

      private

      def headers
        {
          'Content-Type': 'application/json',
          Authorization: "Bearer #{integration.token}"
        }
      end
    end
  end
end
