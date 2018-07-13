module BitbucketServer
  class Connection
    include ActionView::Helpers::SanitizeHelper

    DEFAULT_API_VERSION = '1.0'.freeze

    attr_reader :api_version, :base_uri, :username, :token

    ConnectionError = Class.new(StandardError)

    def initialize(options = {})
      @api_version   = options.fetch(:api_version, DEFAULT_API_VERSION)
      @base_uri      = options[:base_uri]
      @username      = options[:user]
      @token         = options[:password]
    end

    def get(path, extra_query = {})
      response = Gitlab::HTTP.get(build_url(path),
                                  basic_auth: auth,
                                  query: extra_query)

      check_errors!(response)

      response.parsed_response
    end

    def post(path, body)
      response = Gitlab::HTTP.post(build_url(path),
                        basic_auth: auth,
                        headers: post_headers,
                        body: body)

      check_errors!(response)

      response.parsed_response
    end

    private

    def check_errors!(response)
      return if response.code == 200

      details =
        if response.parsed_response && response.parsed_response.is_a?(Hash)
          sanitize(response.parsed_response.dig('errors', 0, 'message'))
        end

      message = "Error #{response.code}"
      message += ": #{details}" if details
      raise ConnectionError, message
    end

    def auth
      @auth ||= { username: username, password: token }
    end

    def post_headers
      @post_headers ||= { 'Content-Type' => 'application/json' }
    end

    def build_url(path)
      return path if path.starts_with?(root_url)

      "#{root_url}#{path}"
    end

    def root_url
      "#{base_uri}/rest/api/#{api_version}"
    end
  end
end
