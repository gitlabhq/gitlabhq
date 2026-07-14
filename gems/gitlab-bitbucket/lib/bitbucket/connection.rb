# frozen_string_literal: true

module Bitbucket
  class Connection
    DEFAULT_API_VERSION = '2.0'
    DEFAULT_BASE_URI    = 'https://api.bitbucket.org/'
    DEFAULT_QUERY       = {}.freeze

    attr_reader :options

    delegate_missing_to :connection

    def initialize(options = {}, http_client:, refresh_strategy: nil)
      @options = options
      @http_client = http_client
      @refresh_strategy = refresh_strategy
    end

    def connection
      @connection ||= if api_connection?
                        Bitbucket::ApiConnection.new(options, http_client: @http_client)
                      else
                        Bitbucket::OauthConnection.new(
                          options,
                          app_id: options.fetch(:app_id),
                          app_secret: options.fetch(:app_secret),
                          refresh_strategy: @refresh_strategy
                        )
                      end
    end

    def get(...)
      connection.get(...)
    end

    def get_response_code(...)
      connection.get_response_code(...)
    end

    def refresh_if_expired!
      connection.refresh_if_expired!
    end

    private

    def api_connection?
      options.key?(:email) && options.key?(:api_token)
    end
  end
end
