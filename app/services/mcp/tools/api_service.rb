# frozen_string_literal: true

module Mcp
  module Tools
    class ApiService < BaseService
      extend Gitlab::Utils::Override

      override :set_cred
      def set_cred(current_user: nil, access_token: nil)
        @access_token = access_token
        _ = current_user
      end

      def execute(request: nil, params: nil)
        if access_token.present?
          super
        else
          Response.error("ApiService: access token is not set")
        end
      end

      protected

      def http_get(oauth_token, path, query = {})
        options = request_options(oauth_token).merge(query: query)
        response = Gitlab::HTTP.get(api_url(path), options)
        handle_response(response)
      end

      def http_post(oauth_token, path, body = {})
        options = request_options(oauth_token).merge(body: body.to_json)
        response = Gitlab::HTTP.post(api_url(path), options)
        handle_response(response)
      end

      private

      def format_response_content(_response)
        raise NoMethodError
      end

      def api_url(path)
        validate_path!(path)
        Gitlab::Utils.append_path(Gitlab.config.gitlab.url, path)
      end

      def validate_path!(path)
        Gitlab::PathTraversal.check_path_traversal!(path)
      rescue Gitlab::PathTraversal::PathTraversalAttackError
        raise ArgumentError, 'path is invalid'
      end

      def request_options(oauth_token)
        {
          headers: {
            'Content-Type' => 'application/json',
            'Authorization' => "Bearer #{oauth_token}"
          }
        }.tap { |opts| opts[:verify] = false if Gitlab.dev_or_test_env? }
      end

      def handle_response(response)
        parsed_response = Gitlab::Json.safe_parse(response.body)

        if response.success?
          return ::Mcp::Tools::Response.error('Invalid JSON response', nil) if parsed_response.nil?

          ::Mcp::Tools::Response.success(
            format_response_content(parsed_response),
            parsed_response
          )
        else
          message = parsed_response&.[]('message') || "HTTP #{response.code}"

          error_payload = parsed_response.nil? ? nil : parsed_response

          ::Mcp::Tools::Response.error(message, error_payload)
        end
      rescue JSON::ParserError, Gitlab::Json::ParserError => e
        ::Mcp::Tools::Response.error('Invalid JSON response', { message: e.message })
      end
    end
  end
end
