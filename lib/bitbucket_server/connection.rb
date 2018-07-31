# frozen_string_literal: true

module BitbucketServer
  class Connection
    include ActionView::Helpers::SanitizeHelper

    DEFAULT_API_VERSION = '1.0'

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
                                  headers: accept_headers,
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

    # We need to support two different APIs for deletion:
    #
    # /rest/api/1.0/projects/{projectKey}/repos/{repositorySlug}/branches/default
    # /rest/branch-utils/1.0/projects/{projectKey}/repos/{repositorySlug}/branches
    def delete(resource, path, body)
      url = delete_url(resource, path)

      response = Gitlab::HTTP.delete(url,
                                     basic_auth: auth,
                                     headers: post_headers,
                                     body: body)

      check_errors!(response)

      response.parsed_response
    end

    private

    def check_errors!(response)
      raise ConnectionError, "Response is not valid JSON" unless response.parsed_response.is_a?(Hash)

      return if response.code >= 200 && response.code < 300

      details = sanitize(response.parsed_response.dig('errors', 0, 'message'))
      message = "Error #{response.code}"
      message += ": #{details}" if details

      raise ConnectionError, message
    rescue JSON::ParserError
      raise ConnectionError, "Unable to parse the server response as JSON"
    end

    def auth
      @auth ||= { username: username, password: token }
    end

    def accept_headers
      @accept_headers ||= { 'Accept' => 'application/json' }
    end

    def post_headers
      @post_headers ||= accept_headers.merge({ 'Content-Type' => 'application/json' })
    end

    def build_url(path)
      return path if path.starts_with?(root_url)

      URI.join(root_url, path).to_s
    end

    def root_url
      URI.join(base_uri, "/rest/api/#{api_version}").to_s
    end

    def delete_url(resource, path)
      if resource == :branches
        URI.join(base_uri, "/rest/branch-utils/#{api_version}#{path}").to_s
      else
        build_url(path)
      end
    end
  end
end
