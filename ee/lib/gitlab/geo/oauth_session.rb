module Gitlab
  module Geo
    class OauthSession
      include ActiveModel::Model

      attr_accessor :access_token
      attr_accessor :state
      attr_accessor :return_to

      def oauth_state_valid?
        return false unless state

        salt, hmac, return_to = state.split(':', 3)

        return false unless return_to

        hmac == generate_oauth_hmac(salt, return_to)
      end

      def generate_oauth_state
        return unless return_to

        hmac = generate_oauth_hmac(oauth_salt, return_to)
        self.state = "#{oauth_salt}:#{hmac}:#{return_to}"
      end

      def generate_logout_state
        return unless access_token

        cipher = logout_token_cipher(oauth_salt, :encrypt)
        encrypted = cipher.update(access_token) + cipher.final
        self.state = "#{oauth_salt}:#{Base64.urlsafe_encode64(encrypted)}"
      rescue OpenSSL::OpenSSLError
        return false
      end

      def extract_logout_token
        return unless state

        salt, encrypted = state.split(':', 2)
        decipher = logout_token_cipher(salt, :decrypt)
        decipher.update(Base64.urlsafe_decode64(encrypted)) + decipher.final
      rescue OpenSSL::OpenSSLError
        return false
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

      def authenticate_with_gitlab(access_token)
        return false unless access_token

        api = OAuth2::AccessToken.from_hash(oauth_client, access_token: access_token)
        api.get('/api/v4/user').parsed
      end

      private

      def generate_oauth_hmac(salt, return_to)
        return false unless return_to

        digest = OpenSSL::Digest.new('sha256')
        key = Gitlab::Application.secrets.secret_key_base + salt
        OpenSSL::HMAC.hexdigest(digest, key, return_to)
      end

      def logout_token_cipher(salt, operation)
        cipher = OpenSSL::Cipher::AES.new(128, :CBC)
        cipher.__send__(operation) # rubocop:disable GitlabSecurity/PublicSend
        cipher.iv = salt
        cipher.key = Gitlab::Application.secrets.db_key_base
        cipher
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
