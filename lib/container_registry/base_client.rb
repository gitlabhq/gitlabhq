# frozen_string_literal: true

require 'faraday'
require 'faraday/follow_redirects'
require 'faraday/retry'
require 'digest'

module ContainerRegistry
  class BaseClient
    DOCKER_DISTRIBUTION_MANIFEST_V2_TYPE = 'application/vnd.docker.distribution.manifest.v2+json'
    DOCKER_DISTRIBUTION_MANIFEST_LIST_V2_TYPE = 'application/vnd.docker.distribution.manifest.list.v2+json'
    OCI_DISTRIBUTION_INDEX_TYPE = 'application/vnd.oci.image.index.v1+json'
    OCI_MANIFEST_V1_TYPE = 'application/vnd.oci.image.manifest.v1+json'
    CONTAINER_IMAGE_V1_TYPE = 'application/vnd.docker.container.image.v1+json'

    ACCEPTED_TYPES = [DOCKER_DISTRIBUTION_MANIFEST_V2_TYPE, OCI_MANIFEST_V1_TYPE].freeze
    ACCEPTED_TYPES_RAW = [DOCKER_DISTRIBUTION_MANIFEST_V2_TYPE, OCI_MANIFEST_V1_TYPE, DOCKER_DISTRIBUTION_MANIFEST_LIST_V2_TYPE, OCI_DISTRIBUTION_INDEX_TYPE].freeze

    RETRY_EXCEPTIONS = [Faraday::Retry::Middleware::DEFAULT_EXCEPTIONS, Faraday::ConnectionFailed].flatten.freeze
    RETRY_OPTIONS = {
      max: 1,
      interval: 5,
      exceptions: RETRY_EXCEPTIONS
    }.freeze

    ERROR_CALLBACK_OPTIONS = {
      callback: ->(env, exception) do
        Gitlab::ErrorTracking.log_exception(
          exception,
          class: name,
          url: env[:url]
        )
      end
    }.freeze

    class << self
      private

      def with_dummy_client(return_value_if_disabled: nil, token_config: { type: :full_access_token, path: nil })
        registry_config = Gitlab.config.registry
        unless registry_config.enabled && registry_config.api_url.present?
          return return_value_if_disabled
        end

        yield new(registry_config.api_url, token: token_from(token_config))
      end

      def token_from(config)
        case config[:type]
        when :full_access_token
          Auth::ContainerRegistryAuthenticationService.access_token({})
        when :nested_repositories_token
          return unless config[:path]

          Auth::ContainerRegistryAuthenticationService.pull_nested_repositories_access_token(config[:path])
        when :push_pull_nested_repositories_token
          return unless config[:path]

          Auth::ContainerRegistryAuthenticationService.push_pull_nested_repositories_access_token(config[:path])
        when :push_pull_move_repositories_access_token
          return unless config[:path].present? && config[:new_path].present?

          Auth::ContainerRegistryAuthenticationService.push_pull_move_repositories_access_token(config[:path], config[:new_path])
        end
      end
    end

    def initialize(base_uri, options = {})
      @base_uri = base_uri
      @options = options
    end

    private

    def faraday(timeout_enabled: true)
      @faraday ||= faraday_base(timeout_enabled: timeout_enabled) do |conn|
        initialize_connection(conn, @options, &method(:configure_connection))
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

    def response_body(response)
      response.body if response && response.success?
    end

    def configure_connection(conn)
      conn.headers['Accept'] = ACCEPTED_TYPES

      conn.response :json, content_type: 'application/json'
      conn.response :json, content_type: 'application/vnd.docker.distribution.manifest.v1+prettyjws'
      conn.response :json, content_type: 'application/vnd.docker.distribution.manifest.v1+json'
      conn.response :json, content_type: DOCKER_DISTRIBUTION_MANIFEST_V2_TYPE
      conn.response :json, content_type: OCI_MANIFEST_V1_TYPE
      conn.response :json, content_type: OCI_DISTRIBUTION_INDEX_TYPE
    end

    def delete_if_exists(path)
      result = faraday.delete(path)

      result.success? || result.status == 404
    end
  end
end
