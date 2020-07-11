# frozen_string_literal: true

module GoogleApi
  class Auth
    attr_reader :access_token, :redirect_uri, :state

    ConfigMissingError = Class.new(StandardError)

    def initialize(access_token, redirect_uri, state: nil)
      @access_token = access_token
      @redirect_uri = redirect_uri
      @state = state
    end

    def authorize_url
      client.auth_code.authorize_url(
        redirect_uri: redirect_uri,
        scope: scope,
        state: state # This is used for arbitrary redirection
      )
    end

    def get_token(code)
      ret = client.auth_code.get_token(code, redirect_uri: redirect_uri)
      [ret.token, ret.expires_at]
    end

    protected

    def scope
      raise NotImplementedError
    end

    private

    def config
      Gitlab::Auth::OAuth::Provider.config_for('google_oauth2')
    end

    def client_options
      config.args.client_options.deep_symbolize_keys
    end

    def client
      return @client if defined?(@client)

      unless config
        raise ConfigMissingError
      end

      @client = ::OAuth2::Client.new(
        config.app_id,
        config.app_secret,
        site: 'https://accounts.google.com',
        token_url: '/o/oauth2/token',
        authorize_url: '/o/oauth2/auth',
        **client_options
      )
    end
  end
end
