module Gitlab
  module Geo
    class RemoteNode
      class InvalidCredentialsError < StandardError; end
      include HTTParty

      API_PREFIX = '/api/v3/'

      def authenticate(access_token)
        opts = {
          query: { access_token: access_token }
        }
        response = self.class.get(authenticate_endpoint, default_opts.merge(opts))

        build_response(response)
      end

      private

      def authenticate_endpoint
        File.join(primary_node_url, API_PREFIX, 'user')
      end

      def primary_node_url
        Gitlab::Geo.primary_node.url
      end

      def default_opts
        {
          headers: { 'Content-Type' => 'application/json' },
        }
      end

      def build_response(response)
        case response.code
        when 200
          response.parsed_response
        when 401
          raise InvalidCredentialsError
        else
          nil
        end
      end
    end
  end
end
