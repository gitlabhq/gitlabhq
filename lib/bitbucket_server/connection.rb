module BitbucketServer
  class Connection
    DEFAULT_API_VERSION = '1.0'.freeze

    attr_reader :api_version, :base_uri, :username, :token

    def initialize(options = {})
      @api_version   = options.fetch(:api_version, DEFAULT_API_VERSION)
      @base_uri      = options[:base_uri]
      @username      = options[:user]
      @token         = options[:password]
    end

    def get(path, extra_query = {})
      auth = { username: username, password: token }
      response = Gitlab::HTTP.get(build_url(path),
                                  basic_auth: auth,
                                  params: extra_query)
      ## Handle failure
      response.parsed_response
    end

    private

    def build_url(path)
      return path if path.starts_with?(root_url)

      "#{root_url}#{path}"
    end

    def root_url
      "#{base_uri}/rest/api/#{api_version}"
    end
  end
end
