# frozen_string_literal: true

module Gitlab
  module ExternalAuthorization
    class Response
      include ::Gitlab::Utils::StrongMemoize

      def initialize(response)
        @response = response
      end

      def valid?
        @response && [200, 401, 403].include?(@response.code)
      end

      def successful?
        valid? && @response.code == 200
      end

      def reason
        parsed_response['reason'] if parsed_response
      end

      private

      def parsed_response
        strong_memoize(:parsed_response) { parse_response! }
      end

      def parse_response!
        Gitlab::Json.parse(@response.body)
      rescue JSON::JSONError
        # The JSON response is optional, so don't fail when it's missing
        nil
      end
    end
  end
end
