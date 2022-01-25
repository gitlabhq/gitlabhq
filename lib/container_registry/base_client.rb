# frozen_string_literal: true

require 'faraday'
require 'faraday_middleware'
require 'digest'

module ContainerRegistry
  class BaseClient
    DOCKER_DISTRIBUTION_MANIFEST_V2_TYPE = 'application/vnd.docker.distribution.manifest.v2+json'
    DOCKER_DISTRIBUTION_MANIFEST_LIST_V2_TYPE = 'application/vnd.docker.distribution.manifest.list.v2+json'
    OCI_MANIFEST_V1_TYPE = 'application/vnd.oci.image.manifest.v1+json'
    CONTAINER_IMAGE_V1_TYPE = 'application/vnd.docker.container.image.v1+json'

    ACCEPTED_TYPES = [DOCKER_DISTRIBUTION_MANIFEST_V2_TYPE, OCI_MANIFEST_V1_TYPE].freeze
    ACCEPTED_TYPES_RAW = [DOCKER_DISTRIBUTION_MANIFEST_V2_TYPE, OCI_MANIFEST_V1_TYPE, DOCKER_DISTRIBUTION_MANIFEST_LIST_V2_TYPE].freeze

    RETRY_EXCEPTIONS = [Faraday::Request::Retry::DEFAULT_EXCEPTIONS, Faraday::ConnectionFailed].flatten.freeze
    RETRY_OPTIONS = {
      max: 1,
      interval: 5,
      exceptions: RETRY_EXCEPTIONS
    }.freeze

    ERROR_CALLBACK_OPTIONS = {
      callback: -> (env, exception) do
        Gitlab::ErrorTracking.log_exception(
          exception,
          class: name,
          url: env[:url]
        )
      end
    }.freeze

    # Taken from: FaradayMiddleware::FollowRedirects
    REDIRECT_CODES = Set.new [301, 302, 303, 307]

    class << self
      private

      def with_dummy_client(return_value_if_disabled: nil)
        registry_config = Gitlab.config.registry
        unless registry_config.enabled && registry_config.api_url.present?
          return return_value_if_disabled
        end

        token = Auth::ContainerRegistryAuthenticationService.access_token([], [])
        yield new(registry_config.api_url, token: token)
      end
    end

    def initialize(base_uri, options = {})
      @base_uri = base_uri
      @options = options
    end

    private

    def faraday(timeout_enabled: true)
      @faraday ||= faraday_base(timeout_enabled: timeout_enabled) do |conn|
        initialize_connection(conn, @options, &method(:accept_manifest))
      end
    end

    def faraday_base(timeout_enabled: true, &block)
      request_options = timeout_enabled ? Gitlab::HTTP::DEFAULT_TIMEOUT_OPTIONS : nil

      Faraday.new(
        @base_uri,
        headers: { user_agent: "GitLab/#{Gitlab::VERSION}" },
        request: request_options,
        &block
      )
    end

    def initialize_connection(conn, options)
      conn.request :json

      if options[:user] && options[:password]
        conn.request(:basic_auth, options[:user].to_s, options[:password].to_s)
      elsif options[:token]
        conn.request(:authorization, :bearer, options[:token].to_s)
      end

      yield(conn) if block_given?

      conn.request(:retry, RETRY_OPTIONS)
      conn.request(:gitlab_error_callback, ERROR_CALLBACK_OPTIONS)
      conn.adapter :net_http
    end

    def response_body(response, allow_redirect: false)
      if allow_redirect && REDIRECT_CODES.include?(response.status)
        response = redirect_response(response.headers['location'])
      end

      response.body if response && response.success?
    end

    def redirect_response(location)
      return unless location

      uri = URI(@base_uri).merge(location)
      raise ArgumentError, "Invalid scheme for #{location}" unless %w[http https].include?(uri.scheme)

      faraday_redirect.get(uri)
    end

    def accept_manifest(conn)
      conn.headers['Accept'] = ACCEPTED_TYPES

      conn.response :json, content_type: 'application/json'
      conn.response :json, content_type: 'application/vnd.docker.distribution.manifest.v1+prettyjws'
      conn.response :json, content_type: 'application/vnd.docker.distribution.manifest.v1+json'
      conn.response :json, content_type: DOCKER_DISTRIBUTION_MANIFEST_V2_TYPE
      conn.response :json, content_type: OCI_MANIFEST_V1_TYPE
    end

    # Create a new request to make sure the Authorization header is not inserted
    # via the Faraday middleware
    def faraday_redirect
      @faraday_redirect ||= faraday_base do |conn|
        conn.request :json

        conn.request(:retry, RETRY_OPTIONS)
        conn.request(:gitlab_error_callback, ERROR_CALLBACK_OPTIONS)
        conn.adapter :net_http
      end
    end

    def delete_if_exists(path)
      result = faraday.delete(path)

      result.success? || result.status == 404
    end
  end
end
