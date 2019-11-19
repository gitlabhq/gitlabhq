# frozen_string_literal: true

require 'faraday'
require 'faraday_middleware'
require 'digest'

module ContainerRegistry
  class Client
    attr_accessor :uri

    DOCKER_DISTRIBUTION_MANIFEST_V2_TYPE = 'application/vnd.docker.distribution.manifest.v2+json'
    OCI_MANIFEST_V1_TYPE = 'application/vnd.oci.image.manifest.v1+json'
    CONTAINER_IMAGE_V1_TYPE = 'application/vnd.docker.container.image.v1+json'

    ACCEPTED_TYPES = [DOCKER_DISTRIBUTION_MANIFEST_V2_TYPE, OCI_MANIFEST_V1_TYPE].freeze

    # Taken from: FaradayMiddleware::FollowRedirects
    REDIRECT_CODES = Set.new [301, 302, 303, 307]

    def initialize(base_uri, options = {})
      @base_uri = base_uri
      @options = options
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

    def delete_repository_tag(name, reference)
      result = faraday.delete("/v2/#{name}/manifests/#{reference}")

      result.success? || result.status == 404
    end

    def upload_raw_blob(path, blob)
      digest = "sha256:#{Digest::SHA256.hexdigest(blob)}"

      if upload_blob(path, blob, digest).success?
        [blob, digest]
      end
    end

    def upload_blob(name, content, digest)
      upload = faraday.post("/v2/#{name}/blobs/uploads/")
      return upload unless upload.success?

      location = URI(upload.headers['location'])

      faraday.put("#{location.path}?#{location.query}") do |req|
        req.params['digest'] = digest
        req.headers['Content-Type'] = 'application/octet-stream'
        req.body = content
      end
    end

    def generate_empty_manifest(path)
      image = {
        config: {}
      }
      image, image_digest = upload_raw_blob(path, JSON.pretty_generate(image))
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
      result = faraday.delete("/v2/#{name}/blobs/#{digest}")

      result.success? || result.status == 404
    end

    def put_tag(name, reference, manifest)
      response = faraday.put("/v2/#{name}/manifests/#{reference}") do |req|
        req.headers['Content-Type'] = DOCKER_DISTRIBUTION_MANIFEST_V2_TYPE
        req.body = JSON.pretty_generate(manifest)
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

    def faraday
      @faraday ||= Faraday.new(@base_uri) do |conn|
        initialize_connection(conn, @options, &method(:accept_manifest))
      end
    end

    def faraday_blob
      @faraday_blob ||= Faraday.new(@base_uri) do |conn|
        initialize_connection(conn, @options)
      end
    end

    # Create a new request to make sure the Authorization header is not inserted
    # via the Faraday middleware
    def faraday_redirect
      @faraday_redirect ||= Faraday.new(@base_uri) do |conn|
        conn.request :json
        conn.adapter :net_http
      end
    end
  end
end

ContainerRegistry::Client.prepend_if_ee('EE::ContainerRegistry::Client')
