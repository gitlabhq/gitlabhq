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
      @connection ||= if app_password_connection?
                        Bitbucket::AppPasswordConnection.new(options)
                      else
                        Bitbucket::OauthConnection.new(options)
                      end
    end

    private

    def app_password_connection?
      options.key?(:username) && options.key?(:app_password)
    end
  end
end
