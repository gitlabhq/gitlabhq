module EE
  module Gitlab
    module ExternalAuthorization
      class Response
        include ::Gitlab::Utils::StrongMemoize

        def initialize(excon_response)
          @excon_response = excon_response
        end

        def valid?
          @excon_response && [200, 401, 403].include?(@excon_response.status)
        end

        def successful?
          valid? && @excon_response.status == 200
        end

        def reason
          parsed_response['reason'] if parsed_response
        end

        private

        def parsed_response
          strong_memoize(:parsed_response) { parse_response! }
        end

        def parse_response!
          JSON.parse(@excon_response.body)
        rescue JSON::JSONError
          # The JSON response is optional, so don't fail when it's missing
          nil
        end
      end
    end
  end
end
