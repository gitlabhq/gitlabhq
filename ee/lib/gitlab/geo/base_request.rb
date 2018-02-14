module Gitlab
  module Geo
    class BaseRequest
      GITLAB_GEO_AUTH_TOKEN_TYPE = 'GL-Geo'.freeze

      attr_reader :request_data

      def initialize(request_data = {})
        @request_data = request_data
      end

      # Raises GeoNodeNotFoundError if current node is not a Geo node
      def headers
        {
          'Authorization' => authorization
        }
      end

      def authorization
        geo_auth_token(request_data)
      end

      def expiration_time
        1.minute
      end

      private

      def geo_auth_token(message)
        geo_node = requesting_node
        raise GeoNodeNotFoundError unless geo_node

        token = JSONWebToken::HMACToken.new(geo_node.secret_access_key)
        token.expire_time = Time.now + expiration_time
        token[:data] = message.to_json

        "#{GITLAB_GEO_AUTH_TOKEN_TYPE} #{geo_node.access_key}:#{token.encoded}"
      end

      def requesting_node
        Gitlab::Geo.current_node
      end
    end
  end
end
