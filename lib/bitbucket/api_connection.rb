# frozen_string_literal: true

module Bitbucket # rubocop:disable Gitlab:BoundedContexts -- existing module
  class ApiConnection
    include Bitbucket::ExponentialBackoff

    attr_reader :username, :app_password, :email, :api_token

    def initialize(options = {})
      @api_version = options.fetch(:api_version, Bitbucket::Connection::DEFAULT_API_VERSION)
      @base_uri = options.fetch(:base_uri, Bitbucket::Connection::DEFAULT_BASE_URI)
      @default_query = options.fetch(:query, Bitbucket::Connection::DEFAULT_QUERY)

      @username = options[:username]
      @app_password = options[:app_password]
      @email = options[:email]
      @api_token = options[:api_token]
    end

    def get(path, extra_query = {})
      response = retry_with_exponential_backoff do
        Import::Clients::HTTP.get(build_url(path), basic_auth: basic_auth, headers: headers, query: extra_query)
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
      if username.present? && app_password.present?
        { username: username, password: app_password }
      elsif email.present? && api_token.present?
        { username: email, password: api_token }
      end
    end

    def headers
      {
        'Accept' => 'application/json'
      }
    end
  end
end
