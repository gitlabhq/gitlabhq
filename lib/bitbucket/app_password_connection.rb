# frozen_string_literal: true

module Bitbucket
  class AppPasswordConnection
    include Bitbucket::ExponentialBackoff

    attr_reader :username, :app_password

    def initialize(options = {})
      @api_version = options.fetch(:api_version, Bitbucket::Connection::DEFAULT_API_VERSION)
      @base_uri = options.fetch(:base_uri, Bitbucket::Connection::DEFAULT_BASE_URI)
      @default_query = options.fetch(:query, Bitbucket::Connection::DEFAULT_QUERY)

      @username = options[:username]
      @app_password = options[:app_password]
    end

    def get(path, extra_query = {})
      response = retry_with_exponential_backoff do
        Gitlab::HTTP.get(build_url(path), basic_auth: basic_auth, headers: headers, query: extra_query)
      end

      response.parsed_response
    end

    private

    def logger
      Gitlab::BitbucketImport::Logger
    end

    def build_url(path)
      return path if path.starts_with?(root_url)

      "#{root_url}#{path}"
    end

    def root_url
      @root_url ||= "#{@base_uri}#{@api_version}"
    end

    def basic_auth
      {
        username: username,
        password: app_password
      }
    end

    def headers
      {
        'Accept' => 'application/json'
      }
    end
  end
end
