require 'faraday'
require 'faraday_middleware'

module ContainerRegistry
  class Client
    attr_accessor :uri

    MANIFEST_VERSION = 'application/vnd.docker.distribution.manifest.v2+json'.freeze

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
      faraday.delete("/v2/#{name}/manifests/#{reference}").success?
    end

    def blob(name, digest, type = nil)
      type ||= 'application/octet-stream'
      response_body faraday_blob.get("/v2/#{name}/blobs/#{digest}", nil, 'Accept' => type), allow_redirect: true
    end

    def delete_blob(name, digest)
      faraday.delete("/v2/#{name}/blobs/#{digest}").success?
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
      conn.headers['Accept'] = MANIFEST_VERSION

      conn.response :json, content_type: 'application/json'
      conn.response :json, content_type: 'application/vnd.docker.distribution.manifest.v1+prettyjws'
      conn.response :json, content_type: 'application/vnd.docker.distribution.manifest.v1+json'
      conn.response :json, content_type: 'application/vnd.docker.distribution.manifest.v2+json'
    end

    def response_body(response, allow_redirect: false)
      if allow_redirect && REDIRECT_CODES.include?(response.status)
        response = redirect_response(response.headers['location'])
      end

      response.body if response && response.success?
    end

    def redirect_response(location)
      return unless location

      faraday_redirect.get(location)
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
