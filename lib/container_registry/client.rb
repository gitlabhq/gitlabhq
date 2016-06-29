require 'faraday'
require 'faraday_middleware'

module ContainerRegistry
  class Client
    attr_accessor :uri

    MANIFEST_VERSION = 'application/vnd.docker.distribution.manifest.v2+json'

    # Taken from: FaradayMiddleware::FollowRedirects
    REDIRECT_CODES  = Set.new [301, 302, 303, 307]

    # Regex that matches characters that need to be escaped in URLs, sans
    # the "%" character which we assume already represents an escaped sequence.
    URI_UNSAFE = /[^\-_.!~*'()a-zA-Z\d;\/?:@&=+$,\[\]%]/

    def initialize(base_uri, options = {})
      @base_uri = base_uri
      @faraday = Faraday.new(@base_uri) do |conn|
        initialize_connection(conn, options)
      end
    end

    def repository_tags(name)
      response_body @faraday.get("/v2/#{name}/tags/list")
    end

    def repository_manifest(name, reference)
      response_body @faraday.get("/v2/#{name}/manifests/#{reference}")
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
      response_body @faraday.get("/v2/#{name}/blobs/#{digest}", nil, headers), allow_redirect: true
    end

    def delete_blob(name, digest)
      @faraday.delete("/v2/#{name}/blobs/#{digest}").success?
    end
    
    private
    
    def initialize_connection(conn, options)
      conn.request :json
      conn.headers['Accept'] = MANIFEST_VERSION

      conn.response :json, content_type: 'application/json'
      conn.response :json, content_type: 'application/vnd.docker.distribution.manifest.v1+prettyjws'
      conn.response :json, content_type: 'application/vnd.docker.distribution.manifest.v1+json'
      conn.response :json, content_type: 'application/vnd.docker.distribution.manifest.v2+json'

      if options[:user] && options[:password]
        conn.request(:basic_auth, options[:user].to_s, options[:password].to_s)
      elsif options[:token]
        conn.request(:authorization, :bearer, options[:token].to_s)
      end

      conn.adapter :net_http
    end

    def response_body(response, allow_redirect: false)
      if allow_redirect && REDIRECT_CODES.include?(response.status)
        response = redirect_response(response.env['url'], response.headers['location'])
      end

      response.body if response && response.success?
    end

    def redirect_response(url, location)
      return unless location

      url += safe_escape(location)

      # We use HTTParty due to fact that @faraday contains internal authorization token
      HTTParty.get(url)
    end

    # Taken from: FaradayMiddleware::FollowRedirects
    # Internal: escapes unsafe characters from an URL which might be a path
    # component only or a fully qualified URI so that it can be joined onto an
    # URI:HTTP using the `+` operator. Doesn't escape "%" characters so to not
    # risk double-escaping.
    def safe_escape(uri)
      uri.to_s.gsub(URI_UNSAFE) { |match|
        '%' + match.unpack('H2' * match.bytesize).join('%').upcase
      }
    end
  end
end
