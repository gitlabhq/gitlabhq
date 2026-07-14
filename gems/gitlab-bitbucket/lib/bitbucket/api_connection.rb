# frozen_string_literal: true

module Bitbucket
  class ApiConnection
    include Bitbucket::ExponentialBackoff

    attr_reader :email, :api_token

    def initialize(options = {}, http_client:)
      @api_version = options.fetch(:api_version, Bitbucket::Connection::DEFAULT_API_VERSION)
      @base_uri = options.fetch(:base_uri, Bitbucket::Connection::DEFAULT_BASE_URI)
      @default_query = options.fetch(:query, Bitbucket::Connection::DEFAULT_QUERY)

      @email = options[:email]
      @api_token = options[:api_token]
      # Fall back to a null logger so ExponentialBackoff#handle_error never calls
      # logger.info on nil when no logger is injected (e.g. controller path).
      @logger = options[:logger] || Logger.new(File::NULL)
      # Required injected HTTP client (the monolith passes Import::Clients::HTTP, which
      # applies the response parser, SSRF protections and the default response-size limit).
      @http_client = http_client
    end

    def get(path, extra_query = {})
      get_with_retry(path, extra_query).parsed_response
    end

    def get_response_code(path, extra_query = {})
      get_with_retry(path, extra_query).code.to_i
    end

    # API token credentials don't expire, so there is nothing to refresh.
    def refresh_if_expired!
      nil
    end

    private

    attr_reader :logger

    def get_with_retry(path, extra_query = {})
      retry_with_exponential_backoff do
        @http_client.get(build_url(path), basic_auth: basic_auth, headers: headers, query: extra_query)
      end
    end

    def build_url(path)
      return path if path.start_with?(root_url)

      "#{root_url}#{path}"
    end

    def root_url
      @root_url ||= "#{@base_uri}#{@api_version}"
    end

    def basic_auth
      { username: email, password: api_token }
    end

    def headers
      {
        'Accept' => 'application/json'
      }
    end
  end
end
