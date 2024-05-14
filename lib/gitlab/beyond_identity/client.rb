# frozen_string_literal: true

module Gitlab
  module BeyondIdentity
    class Client
      API_URL = "https://api.byndid.com/key-mgmt/v0/gpg/key/authorization/git-commit-signing"

      Error = Class.new(StandardError)

      class ApiError < Class.new(StandardError)
        ACCEPTABLE_ERROR_CODES = [404].freeze

        attr_reader :code, :message

        def initialize(message, code)
          @code = code
          @message = message
        end

        # In some cases, we treat error response as acceptable:
        #
        # A GPG key that wasn't issued by BeyondIdentity returns 404 status code
        # but users should be able to add those GPG keys to their profile.
        def acceptable_error?
          ACCEPTABLE_ERROR_CODES.include?(code)
        end
      end

      attr_reader :integration

      def initialize(integration)
        raise Error, 'integration is not activated' unless integration.activated?

        @integration = integration
      end

      def execute(params)
        options = { headers: headers, query: params }
        response = Gitlab::HTTP.get(API_URL, options)
        body = Gitlab::Json.parse(response.body) || {}

        raise ApiError.new(body.dig('error', 'message'), response.code) unless response.success?
        raise ApiError.new(body['message'], response.code) unless body['authorized']

        body
      rescue JSON::ParserError
        raise ApiError.new('invalid response format', response.code)
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
