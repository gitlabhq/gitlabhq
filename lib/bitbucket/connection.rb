module Bitbucket
  class Connection
    DEFAULT_API_VERSION = '2.0'.freeze
    DEFAULT_BASE_URI    = 'https://api.bitbucket.org/'.freeze
    DEFAULT_QUERY       = {}.freeze

    attr_reader :expires_at, :expires_in, :refresh_token, :token

    def initialize(options = {})
      @api_version   = options.fetch(:api_version, DEFAULT_API_VERSION)
      @base_uri      = options.fetch(:base_uri, DEFAULT_BASE_URI)
      @default_query = options.fetch(:query, DEFAULT_QUERY)

      @token         = options[:token]
      @expires_at    = options[:expires_at]
      @expires_in    = options[:expires_in]
      @refresh_token = options[:refresh_token]
    end

    def get(path, extra_query = {})
      refresh! if expired?

      response = connection.get(build_url(path), params: @default_query.merge(extra_query))
      response.parsed
    end

    delegate :expired?, to: :connection

    def refresh!
      response = connection.refresh!

      @token         = response.token
      @expires_at    = response.expires_at
      @expires_in    = response.expires_in
      @refresh_token = response.refresh_token
      @connection    = nil
    end

    private

    def client
      @client ||= OAuth2::Client.new(provider.app_id, provider.app_secret, options)
    end

    def connection
      @connection ||= OAuth2::AccessToken.new(client, @token, refresh_token: @refresh_token, expires_at: @expires_at, expires_in: @expires_in)
    end

    def build_url(path)
      return path if path.starts_with?(root_url)

      "#{root_url}#{path}"
    end

    def root_url
      @root_url ||= "#{@base_uri}#{@api_version}"
    end

    def provider
      Gitlab::Auth::OAuth::Provider.config_for('bitbucket')
    end

    def options
      OmniAuth::Strategies::Bitbucket.default_options[:client_options].deep_symbolize_keys
    end
  end
end
