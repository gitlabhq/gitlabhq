require 'faraday'
require 'faraday_middleware'

module ImageRegistry
  class Client
    attr_accessor :uri

    MANIFEST_VERSION = 'application/vnd.docker.distribution.manifest.v2+json'

    def initialize(base_uri, options = {})
      @base_uri = base_uri
      @faraday = Faraday.new(@base_uri) do |builder|
        builder.request :json
        builder.headers['Accept'] = MANIFEST_VERSION

        builder.response :json, :content_type => /\bjson$/
        builder.response :json, :content_type => 'application/vnd.docker.distribution.manifest.v1+prettyjws'

        if options[:user] && options[:password]
          builder.request(:basic_auth, options[:user].to_s, options[:password].to_s)
        elsif options[:token]
          builder.request(:authentication, :Bearer, options[:token].to_s)
        end

        builder.adapter :net_http
      end
    end

    def repository_tags(name)
      @faraday.get("/v2/#{name}/tags/list").body
    end

    def repository_manifest(name, reference)
      @faraday.get("/v2/#{name}/manifests/#{reference}").body
    end

    def put_repository_manifest(name, reference, manifest)
      @faraday.put("/v2/#{name}/manifests/#{reference}", manifest, { "Content-Type" => MANIFEST_VERSION }).success?
    end

    def repository_mount_blob(name, digest, from)
      @faraday.post("/v2/#{name}/blobs/uploads/?mount=#{digest}&from=#{from}").status == 201
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
  end
end
