module Gitlab
  module Geo
    class OauthSession
      include ActiveModel::Model

      attr_accessor :state
      attr_accessor :return_to

      def is_oauth_state_valid?
        return true unless state
        salt, hmac, return_to = state.split(':', 3)

        return false unless return_to
        hmac == generate_oauth_hmac(salt, return_to)
      end

      def generate_oauth_state
        return unless return_to
        hmac = generate_oauth_hmac(oauth_salt, return_to)
        "#{oauth_salt}:#{hmac}:#{return_to}"
      end

      def get_oauth_state_return_to
        state.split(':', 3)[2] if state
      end

      def authorize_url(params = {})
        oauth_client.auth_code.authorize_url(params)
      end

      def get_token(code, params = {}, opts = {})
        oauth_client.auth_code.get_token(code, params, opts).token
      end

      private

      def generate_oauth_hmac(salt, return_to)
        return false unless return_to
        digest = OpenSSL::Digest.new('sha256')
        key = Gitlab::Application.secrets.secret_key_base + salt
        OpenSSL::HMAC.hexdigest(digest, key, return_to)
      end

      def oauth_salt
        @salt ||= SecureRandom.hex(16)
      end

      def oauth_client
        @client ||= begin
          ::OAuth2::Client.new(
            oauth_app.uid,
            oauth_app.secret,
            {
              site: primary_node_url,
              authorize_url: 'oauth/authorize',
              token_url: 'oauth/token'
            }
          )
        end
      end

      def oauth_app
        Gitlab::Geo.oauth_authentication
      end

      def primary_node_url
        Gitlab::Geo.primary_node.url
      end
    end
  end
end
