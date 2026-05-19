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

    def get(...)
      connection.get(...)
    end

    private

    def api_connection?
      options.key?(:email) && options.key?(:api_token)
    end
  end
end
