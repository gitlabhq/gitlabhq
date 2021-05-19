# frozen_string_literal: true

require 'faraday'
require 'faraday_middleware'
require 'digest'

module ContainerRegistry
  class Client
    include Gitlab::Utils::StrongMemoize

    attr_accessor :uri

    DOCKER_DISTRIBUTION_MANIFEST_V2_TYPE = 'application/vnd.docker.distribution.manifest.v2+json'
    OCI_MANIFEST_V1_TYPE = 'application/vnd.oci.image.manifest.v1+json'
    CONTAINER_IMAGE_V1_TYPE = 'application/vnd.docker.container.image.v1+json'
    REGISTRY_VERSION_HEADER = 'gitlab-container-registry-version'
    REGISTRY_FEATURES_HEADER = 'gitlab-container-registry-features'
    REGISTRY_TAG_DELETE_FEATURE = 'tag_delete'

    ACCEPTED_TYPES = [DOCKER_DISTRIBUTION_MANIFEST_V2_TYPE, OCI_MANIFEST_V1_TYPE].freeze

    # Taken from: FaradayMiddleware::FollowRedirects
    REDIRECT_CODES = Set.new [301, 302, 303, 307]

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

    def self.supports_tag_delete?
      registry_config = Gitlab.config.registry
      return false unless registry_config.enabled && registry_config.api_url.present?

      token = Auth::ContainerRegistryAuthenticationService.access_token([], [])
      client = new(registry_config.api_url, token: token)
      client.supports_tag_delete?
    end

    def initialize(base_uri, options = {})
      @base_uri = base_uri
      @options = options
    end

    def registry_info
      response = faraday.get("/v2/")

      return {} unless response&.success?

      version = response.headers[REGISTRY_VERSION_HEADER]
      features = response.headers.fetch(REGISTRY_FEATURES_HEADER, '')

      {
        version: version,
        features: features.split(',').map(&:strip),
        vendor: version ? 'gitlab' : 'other'
      }
    end

    def repository_tags(name)
      response_body faraday.get("/v2/#{name}/tags/list")
    end

    def repository_manifest(name, reference)
      response_body faraday.get("/v2/#{name}/manifests/#{reference}")
    end

    def repository_tag_digest(name, reference)
      response = faraday.head("/v2/#{name}/manifests/#{reference}")
      response.headers['docker-content-digest'] if response.success?
    end

    def delete_repository_tag_by_digest(name, reference)
      delete_if_exists("/v2/#{name}/manifests/#{reference}")
    end

    def delete_repository_tag_by_name(name, reference)
      delete_if_exists("/v2/#{name}/tags/reference/#{reference}")
    end

    # Check if the registry supports tag deletion. This is only supported by the
    # GitLab registry fork. The fastest and safest way to check this is to send
    # an OPTIONS request to /v2/<name>/tags/reference/<tag>, using a random
    # repository name and tag (the registry won't check if they exist).
    # Registries that support tag deletion will reply with a 200 OK and include
    # the DELETE method in the Allow header. Others reply with an 404 Not Found.
    def supports_tag_delete?
      strong_memoize(:supports_tag_delete) do
        registry_features = Gitlab::CurrentSettings.container_registry_features || []
        next true if ::Gitlab.com? && registry_features.include?(REGISTRY_TAG_DELETE_FEATURE)

        response = faraday.run_request(:options, '/v2/name/tags/reference/tag', '', {})
        response.success? && response.headers['allow']&.include?('DELETE')
      end
    end

    def upload_raw_blob(path, blob)
      digest = "sha256:#{Digest::SHA256.hexdigest(blob)}"

      if upload_blob(path, blob, digest).success?
        [blob, digest]
      end
    end

    def upload_blob(name, content, digest)
      upload = faraday(timeout_enabled: false).post("/v2/#{name}/blobs/uploads/")
      return upload unless upload.success?

      location = URI(upload.headers['location'])

      faraday(timeout_enabled: false).put("#{location.path}?#{location.query}") do |req|
        req.params['digest'] = digest
        req.headers['Content-Type'] = 'application/octet-stream'
        req.body = content
      end
    end

    def generate_empty_manifest(path)
      image = {
        config: {}
      }
      image, image_digest = upload_raw_blob(path, Gitlab::Json.pretty_generate(image))
      return unless image

      {
        schemaVersion: 2,
        mediaType: DOCKER_DISTRIBUTION_MANIFEST_V2_TYPE,
        config: {
          mediaType: CONTAINER_IMAGE_V1_TYPE,
          size: image.size,
          digest: image_digest
        }
      }
    end

    def blob(name, digest, type = nil)
      type ||= 'application/octet-stream'
      response_body faraday_blob.get("/v2/#{name}/blobs/#{digest}", nil, 'Accept' => type), allow_redirect: true
    end

    def delete_blob(name, digest)
      delete_if_exists("/v2/#{name}/blobs/#{digest}")
    end

    def put_tag(name, reference, manifest)
      response = faraday(timeout_enabled: false).put("/v2/#{name}/manifests/#{reference}") do |req|
        req.headers['Content-Type'] = DOCKER_DISTRIBUTION_MANIFEST_V2_TYPE
        req.body = Gitlab::Json.pretty_generate(manifest)
      end

      response.headers['docker-content-digest'] if response.success?
    end

    private

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

    def accept_manifest(conn)
      conn.headers['Accept'] = ACCEPTED_TYPES

      conn.response :json, content_type: 'application/json'
      conn.response :json, content_type: 'application/vnd.docker.distribution.manifest.v1+prettyjws'
      conn.response :json, content_type: 'application/vnd.docker.distribution.manifest.v1+json'
      conn.response :json, content_type: DOCKER_DISTRIBUTION_MANIFEST_V2_TYPE
      conn.response :json, content_type: OCI_MANIFEST_V1_TYPE
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

    def faraday(timeout_enabled: true)
      @faraday ||= faraday_base(timeout_enabled: timeout_enabled) do |conn|
        initialize_connection(conn, @options, &method(:accept_manifest))
      end
    end

    def faraday_blob
      @faraday_blob ||= faraday_base do |conn|
        initialize_connection(conn, @options)
      end
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

    def faraday_base(timeout_enabled: true, &block)
      request_options = timeout_enabled ? Gitlab::HTTP::DEFAULT_TIMEOUT_OPTIONS : nil

      Faraday.new(
        @base_uri,
        headers: { user_agent: "GitLab/#{Gitlab::VERSION}" },
        request: request_options,
        &block
      )
    end

    def delete_if_exists(path)
      result = faraday.delete(path)

      result.success? || result.status == 404
    end
  end
end

ContainerRegistry::Client.prepend_mod_with('ContainerRegistry::Client')
