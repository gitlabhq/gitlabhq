module Gitlab
  module Geo
    class TransferRequest
      GITLAB_GEO_AUTH_TOKEN_TYPE = 'GL-Geo'.freeze

      attr_reader :request_data

      def initialize(request_data)
        @request_data = request_data
      end

      def header
        {
          "Authorization" => geo_transfer_auth(request_data.to_json),
          "X-Sendfile-Type" => "X-Sendfile"
        }
      end

      private

      def geo_transfer_auth(message)
        geo_node = requesting_node

        return unless geo_node

        payload = { data: message, iat: Time.now.to_i }
        token = JWT.encode(payload, geo_node.secret_access_key, 'HS256')

        "#{GITLAB_GEO_AUTH_TOKEN_TYPE} #{geo_node.access_key}:#{token}"
      end

      def requesting_node
        Gitlab::Geo.current_node
      end
    end
  end
end
