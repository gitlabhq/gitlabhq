# frozen_string_literal: true

module BitbucketServer
  class Connection
    include ActionView::Helpers::SanitizeHelper
    include BitbucketServer::RetryWithDelay

    DEFAULT_API_VERSION = '1.0'
    SEPARATOR = '/'

    NETWORK_ERRORS = [
      SocketError,
      OpenSSL::SSL::SSLError,
      Errno::ECONNRESET,
      Errno::ECONNREFUSED,
      Errno::EHOSTUNREACH,
      Net::OpenTimeout,
      Net::ReadTimeout,
      URI::InvalidURIError,
      Gitlab::HTTP::BlockedUrlError
    ].freeze

    attr_reader :api_version, :base_uri, :username, :token

    class ConnectionError < StandardError
      RETRYABLE_HTTP_STATUS_CODES = [408, 429].freeze

      attr_reader :http_status_code

      def initialize(message = nil, http_status_code: nil)
        super(message)
        @http_status_code = http_status_code
      end

      def retryable?
        return true unless http_status_code

        RETRYABLE_HTTP_STATUS_CODES.include?(http_status_code) || http_status_code.in?(500..599)
      end
    end

    def initialize(options = {})
      @api_version = options.fetch(:api_version, DEFAULT_API_VERSION)
      @base_uri = options[:base_uri]
      @username = options[:user]
      @token = options[:password]
    end

    def get(path, extra_query = {})
      response = retry_with_delay do
        Import::Clients::HTTP.get(build_url(path), basic_auth: auth, headers: accept_headers, query: extra_query)
      end

      check_errors!(response)

      response.parsed_response
    rescue *NETWORK_ERRORS => e
      raise ConnectionError, e
    end

    def post(path, body)
      response = retry_with_delay do
        Import::Clients::HTTP.post(build_url(path), basic_auth: auth, headers: post_headers, body: body)
      end

      check_errors!(response)

      response.parsed_response
    rescue *NETWORK_ERRORS => e
      raise ConnectionError, e
    end

    # We need to support two different APIs for deletion:
    #
    # /rest/api/1.0/projects/{projectKey}/repos/{repositorySlug}/branches/default
    # /rest/branch-utils/1.0/projects/{projectKey}/repos/{repositorySlug}/branches
    def delete(resource, path, body)
      url = delete_url(resource, path)

      response = retry_with_delay do
        Import::Clients::HTTP.delete(url, basic_auth: auth, headers: post_headers, body: body)
      end

      check_errors!(response)

      response.parsed_response
    rescue *NETWORK_ERRORS => e
      raise ConnectionError, e
    end

    private

    def check_errors!(response)
      return if ActionDispatch::Response::NO_CONTENT_CODES.include?(response.code)
      raise ConnectionError, "Response is not valid JSON" unless response.parsed_response.is_a?(Hash)

      return if response.code >= 200 && response.code < 300

      details = sanitize(response.parsed_response.dig('errors', 0, 'message'))
      message = "Error #{response.code}"
      message += ": #{details}" if details

      raise ConnectionError.new(message, http_status_code: response.code)
    rescue JSON::NestingError
      raise
    rescue JSON::ParserError
      raise ConnectionError, "Unable to parse the server response as JSON"
    end

    def auth
      @auth ||= { username: username, password: token }
    end

    def accept_headers
      @accept_headers ||= { 'Accept' => 'application/json' }
    end

    def post_headers
      @post_headers ||= accept_headers.merge({ 'Content-Type' => 'application/json' })
    end

    def build_url(path)
      return path if path.starts_with?(root_url)

      Gitlab::Utils.append_path(root_url, path)
    end

    def root_url
      Gitlab::Utils.append_path(base_uri, "rest/api/#{api_version}")
    end

    def delete_url(resource, path)
      if resource == :branches
        Gitlab::Utils.append_path(base_uri, "rest/branch-utils/#{api_version}#{path}")
      else
        build_url(path)
      end
    end

    def logger
      Gitlab::BitbucketServerImport::Logger
    end
  end
end
