# frozen_string_literal: true

module Atlassian
  module JiraConnect
    class Client < ::Atlassian::Jira::DevInfoClient
      def initialize(base_uri, shared_secret)
        @shared_secret = shared_secret

        super(base_uri)
      end

      private

      def headers(uri, http_method = 'POST')
        {
          'Authorization' => "JWT #{jwt_token(http_method, uri)}",
          'Content-Type' => 'application/json',
          'Accept' => 'application/json'
        }
      end

      def auth_error_message
        'Invalid JWT'
      end

      def jwt_token(http_method, uri)
        claims = Atlassian::Jwt.build_claims(
          Atlassian::JiraConnect.app_key,
          uri,
          http_method,
          @base_uri
        )

        Atlassian::Jwt.encode(claims, @shared_secret)
      end
    end
  end
end
