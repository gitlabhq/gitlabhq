# frozen_string_literal: true

module Bitbucket
  class OauthConnection
    include Bitbucket::ExponentialBackoff

    attr_reader :expires_at, :expires_in, :refresh_token, :token

    def initialize(options = {}, refresh_strategy: nil)
      @api_version   = options.fetch(:api_version, Bitbucket::Connection::DEFAULT_API_VERSION)
      @base_uri      = options.fetch(:base_uri, Bitbucket::Connection::DEFAULT_BASE_URI)
      @default_query = options.fetch(:query, Bitbucket::Connection::DEFAULT_QUERY)

      @token            = options[:token]
      @expires_at       = options[:expires_at]
      @expires_in       = options[:expires_in]
      @refresh_token    = options[:refresh_token]
      @refresh_strategy = refresh_strategy
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

    def get_with_retry(path, extra_query = {})
      retry_with_exponential_backoff do
        refresh! if expired?

        connection.get(build_url(path), params: @default_query.merge(extra_query))
      end
    end

    def client
      @client ||= OAuth2::Client.new(provider.app_id, provider.app_secret, options)
    end

    def logger
      Gitlab::BitbucketImport::Logger
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
      OmniAuth::Strategies::Bitbucket.default_options[:client_options].to_h.deep_symbolize_keys
    end
  end
end
