# frozen_string_literal: true

module ContainerRegistry
  class Client < BaseClient
    include Gitlab::Utils::StrongMemoize

    attr_accessor :uri
    attr_reader :options, :base_uri

    REGISTRY_VERSION_HEADER = 'gitlab-container-registry-version'
    REGISTRY_FEATURES_HEADER = 'gitlab-container-registry-features'
    REGISTRY_TAG_DELETE_FEATURE = 'tag_delete'
    REGISTRY_DB_ENABLED_HEADER = 'gitlab-container-registry-database-enabled'

    DEFAULT_TAGS_PAGE_SIZE = 10000

    ALLOWED_REDIRECT_SCHEMES = %w[http https].freeze
    REDIRECT_OPTIONS = {
      clear_authorization_header: true,
      limit: 3,
      cookies: [],
      callback: ->(response_env, request_env) do
        request_env.request_headers.delete(::Faraday::FollowRedirects::Middleware::AUTH_HEADER)

        redirect_to = request_env.url
        unless redirect_to.scheme.in?(ALLOWED_REDIRECT_SCHEMES)
          raise ArgumentError, "Invalid scheme for #{redirect_to}"
        end
      end
    }.freeze

    def self.supports_tag_delete?
      with_dummy_client(return_value_if_disabled: false) do |client|
        client.supports_tag_delete?
      end
    end

    def self.registry_info
      with_dummy_client do |client|
        client.registry_info
      end
    end

    def registry_info
      response = faraday.get("/v2/")

      return {} unless response&.success?

      version = response.headers[REGISTRY_VERSION_HEADER]
      features = response.headers.fetch(REGISTRY_FEATURES_HEADER, '')
      db_enabled = response.headers.fetch(REGISTRY_DB_ENABLED_HEADER, '')

      {
        version: version,
        features: features.split(',').map(&:strip),
        vendor: version ? 'gitlab' : 'other',
        db_enabled: ::Gitlab::Utils.to_boolean(db_enabled, default: false)
      }
    end

    def connected?
      !registry_info.empty?
    end

    def repository_tags(name, page_size: DEFAULT_TAGS_PAGE_SIZE)
      response = faraday.get("/v2/#{name}/tags/list") do |req|
        req.params['n'] = page_size
      end
      response_body(response)
    end

    def repository_manifest(name, reference)
      response_body faraday.get("/v2/#{name}/manifests/#{reference}")
    end

    def repository_tag_digest(name, reference)
      response = faraday.head("/v2/#{name}/manifests/#{reference}")
      response.headers[DependencyProxy::Manifest::DIGEST_HEADER] if response.success?
    end

    def delete_repository_tag_by_digest(name, reference)
      delete_if_exists("/v2/#{name}/manifests/#{reference}")
    end

    # Check if the registry supports tag deletion. This is only supported by the
    # GitLab registry fork. The fastest and safest way to check this is to send
    # an OPTIONS request to /v2/<name>/manifests/<tag>, using a random
    # repository name and tag (the registry won't check if they exist).
    # Registries that support tag deletion will reply with a 200 OK and include
    # the DELETE method in the Allow header. Others reply with an 404 Not Found.
    def supports_tag_delete?
      strong_memoize(:supports_tag_delete) do
        registry_features = Gitlab::CurrentSettings.container_registry_features || []
        next true if ::Gitlab.com_except_jh? && registry_features.include?(REGISTRY_TAG_DELETE_FEATURE)

        response = faraday.run_request(:options, '/v2/name/manifests/tag', '', {})
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
      response_body faraday_blob.get("/v2/#{name}/blobs/#{digest}", nil, 'Accept' => type)
    end

    def delete_blob(name, digest)
      delete_if_exists("/v2/#{name}/blobs/#{digest}")
    end

    def put_tag(name, reference, manifest)
      response = faraday(timeout_enabled: false).put("/v2/#{name}/manifests/#{reference}") do |req|
        req.headers['Content-Type'] = DOCKER_DISTRIBUTION_MANIFEST_V2_TYPE
        req.body = Gitlab::Json.pretty_generate(manifest)
      end

      response.headers[DependencyProxy::Manifest::DIGEST_HEADER] if response.success?
    end

    private

    def faraday_blob
      @faraday_blob ||= faraday_base do |conn|
        initialize_connection(conn, @options)

        conn.use ::Faraday::FollowRedirects::Middleware, REDIRECT_OPTIONS
      end
    end
  end
end

ContainerRegistry::Client.prepend_mod_with('ContainerRegistry::Client')
