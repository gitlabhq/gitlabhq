# frozen_string_literal: true

module Bitbucket
  class Connection
    DEFAULT_API_VERSION = '2.0'
    DEFAULT_BASE_URI    = 'https://api.bitbucket.org/'
    DEFAULT_QUERY       = {}.freeze

    attr_reader :options

    delegate_missing_to :connection

    def initialize(options = {})
      @options = options
    end

    def connection
      @connection ||= if api_connection?
                        Bitbucket::ApiConnection.new(options)
                      else
                        Bitbucket::OauthConnection.new(options)
                      end
    end

    private

    def api_connection?
      app_password_connection? || api_token_connection?
    end

    def app_password_connection?
      options.key?(:username) && options.key?(:app_password)
    end

    def api_token_connection?
      options.key?(:email) && options.key?(:api_token)
    end
  end
end
