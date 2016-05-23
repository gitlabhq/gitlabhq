require 'faraday'
require 'faraday_middleware'

module ContainerRegistry
  class Client
    attr_accessor :uri

    MANIFEST_VERSION = 'application/vnd.docker.distribution.manifest.v2+json'

    def initialize(base_uri, options = {})
      @base_uri = base_uri
      @faraday = Faraday.new(@base_uri) do |conn|
        initialize_connection(conn, options)
      end
    end

    def repository_tags(name)
      @faraday.get("/v2/#{name}/tags/list").body
    end

    def repository_manifest(name, reference)
      @faraday.get("/v2/#{name}/manifests/#{reference}").body
    end

    def repository_tag_digest(name, reference)
      response = @faraday.head("/v2/#{name}/manifests/#{reference}")
      response.headers['docker-content-digest'] if response.success?
    end

    def delete_repository_tag(name, reference)
      @faraday.delete("/v2/#{name}/manifests/#{reference}").success?
    end

    def blob(name, digest, type = nil)
      headers = {}
      headers['Accept'] = type if type
      @faraday.get("/v2/#{name}/blobs/#{digest}", nil, headers).body
    end

    def delete_blob(name, digest)
      @faraday.delete("/v2/#{name}/blobs/#{digest}").success?
    end
    
    private
    
    def initialize_connection(conn, options)
      conn.request :json
      conn.headers['Accept'] = MANIFEST_VERSION

      conn.response :json, content_type: /\bjson$/

      if options[:user] && options[:password]
        conn.request(:basic_auth, options[:user].to_s, options[:password].to_s)
      elsif options[:token]
        conn.request(:authorization, :bearer, options[:token].to_s)
      end

      conn.adapter :net_http
    end
  end
end
