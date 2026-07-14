# frozen_string_literal: true

module Bitbucket
  class OauthConnection
    include Bitbucket::ExponentialBackoff

    attr_reader :expires_at, :expires_in, :refresh_token, :token

    # app_id/app_secret are required: refreshing the OAuth token (directly via the
    # controller, or through an injected refresh_strategy in the importer) builds an
    # OAuth2::Client from them, so they are mandatory rather than pulled from options.
    # Callers inject them instead of calling Gitlab::Auth::OAuth::Provider.config_for('bitbucket').
    def initialize(options = {}, app_id:, app_secret:, refresh_strategy: nil)
      @api_version   = options.fetch(:api_version, Bitbucket::Connection::DEFAULT_API_VERSION)
      @base_uri      = options.fetch(:base_uri, Bitbucket::Connection::DEFAULT_BASE_URI)
      @default_query = options.fetch(:query, Bitbucket::Connection::DEFAULT_QUERY)

      @token            = options[:token]
      @expires_at       = options[:expires_at]
      @expires_in       = options[:expires_in]
      @refresh_token    = options[:refresh_token]
      @refresh_strategy = refresh_strategy

      # Fall back to a null logger so ExponentialBackoff#handle_error never calls
      # logger.info on nil when no logger is injected (e.g. controller path).
      @logger = options[:logger] || Logger.new(File::NULL)

      @app_id        = app_id
      @app_secret    = app_secret
      @oauth_options = options[:oauth_options]
    end

    def get(path, extra_query = {})
      get_with_retry(path, extra_query).parsed
    end

    def get_response_code(path, extra_query = {})
      get_with_retry(path, extra_query).status
    rescue OAuth2::Error => e
      e.response.status
    end

    delegate :expired?, to: :connection

    def refresh!
      return @refresh_strategy.refresh(self) if @refresh_strategy

      perform_refresh!
    end

    def refresh_if_expired!
      refresh! if expired?
    end

    def perform_refresh!
      response = connection.refresh!

      @token         = response.token
      @expires_at    = response.expires_at
      @expires_in    = response.expires_in
      @refresh_token = response.refresh_token
      @connection    = nil
    end

    def adopt_credentials(token:, expires_at:, expires_in:, refresh_token:)
      @token         = token
      @expires_at    = expires_at
      @expires_in    = expires_in
      @refresh_token = refresh_token
      @connection    = nil
    end

    private

    attr_reader :logger

    def get_with_retry(path, extra_query = {})
      retry_with_exponential_backoff do
        refresh_if_expired!

        connection.get(build_url(path), params: @default_query.merge(extra_query))
      end
    end

    def client
      @client ||= OAuth2::Client.new(@app_id, @app_secret, oauth_options)
    end

    def connection
      @connection ||= OAuth2::AccessToken.new(
        client,
        @token,
        refresh_token: @refresh_token,
        expires_at: @expires_at,
        expires_in: @expires_in
      )
    end

    def oauth_options
      return @oauth_options if @oauth_options

      # Fall back to the OmniAuth strategy defaults when no explicit options are injected.
      # This path is used when constructing the connection directly (e.g. from a controller
      # before the importer credentials are stored), and OmniAuth must already be loaded.
      OmniAuth::Strategies::Bitbucket.default_options[:client_options].to_h.deep_symbolize_keys
    end

    def build_url(path)
      return path if path.start_with?(root_url)

      "#{root_url}#{path}"
    end

    def root_url
      @root_url ||= "#{@base_uri}#{@api_version}"
    end
  end
end
