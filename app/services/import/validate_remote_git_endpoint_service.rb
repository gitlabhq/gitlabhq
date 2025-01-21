# frozen_string_literal: true

module Import
  class ValidateRemoteGitEndpointService
    # Validates if the remote endpoint is a valid GIT repository
    # Only smart protocol is supported
    # Validation rules are taken from https://git-scm.com/docs/http-protocol#_smart_clients

    GIT_SERVICE_NAME = "git-upload-pack"
    GIT_EXPECTED_FIRST_PACKET_LINE = "# service=#{GIT_SERVICE_NAME}"
    GIT_BODY_MESSAGE_REGEXP = /^[0-9a-fA-F]{4}#{GIT_EXPECTED_FIRST_PACKET_LINE}/
    # https://github.com/git/git/blob/master/Documentation/technical/protocol-common.txt#L56-L59
    GIT_PROTOCOL_PKT_LEN = 4
    GIT_MINIMUM_RESPONSE_LENGTH = GIT_PROTOCOL_PKT_LEN + GIT_EXPECTED_FIRST_PACKET_LINE.length
    EXPECTED_CONTENT_TYPE = "application/x-#{GIT_SERVICE_NAME}-advertisement"
    INVALID_BODY_MESSAGE = 'Not a git repository: Invalid response body'
    INVALID_CONTENT_TYPE_MESSAGE = 'Not a git repository: Invalid content-type'

    def initialize(params)
      @params = params
      @auth = nil
    end

    def execute
      uri = Gitlab::Utils.parse_url(@params[:url])

      if !uri || !uri.hostname || Project::VALID_IMPORT_PROTOCOLS.exclude?(uri.scheme)
        return ServiceResponse.error(message: "#{@params[:url]} is not a valid URL")
      end

      # Credentials extracted from URL will be rewritten
      # if credentials were also set via params
      extract_auth_credentials!(uri)
      set_auth_from_params

      return ServiceResponse.success if uri.scheme == 'git'

      uri.fragment = nil
      url = Gitlab::Utils.append_path(uri.to_s, "/info/refs?service=#{GIT_SERVICE_NAME}")

      response, response_body = http_get_and_extract_first_chunks(url)

      validate(uri, response, response_body)
    rescue *Gitlab::HTTP::HTTP_ERRORS => err
      error_result("HTTP #{err.class.name.underscore} error: #{err.message}")
    rescue StandardError => err
      ServiceResponse.error(
        message: "Internal #{err.class.name.underscore} error: #{err.message}",
        reason: 500
      )
    end

    private

    attr_reader :auth

    def extract_auth_credentials!(uri)
      if uri.userinfo.present?
        @auth = { username: uri.user, password: uri.password }

        # Remove username/password params from URL after extraction,
        # because they will be sent via Basic authorization header
        uri.userinfo = nil
      end
    end

    def set_auth_from_params
      @auth = { username: @params[:user], password: @params[:password] } if @params[:user].present?
    end

    def http_get_and_extract_first_chunks(url)
      # We are interested only in the first chunks of the response
      # So we're using stream_body: true and breaking when receive enough body
      response = nil
      response_body = ''

      Gitlab::HTTP.get(url, stream_body: true, follow_redirects: false, basic_auth: auth) do |response_chunk|
        response = response_chunk
        response_body += response_chunk
        break if GIT_MINIMUM_RESPONSE_LENGTH <= response_body.length
      end

      [response, response_body]
    end

    def validate(uri, response, response_body)
      return status_code_error(uri, response) unless status_code_is_valid?(response)
      return error_result(INVALID_CONTENT_TYPE_MESSAGE) unless content_type_is_valid?(response)
      return error_result(INVALID_BODY_MESSAGE) unless response_body_is_valid?(response_body)

      ServiceResponse.success
    end

    def status_code_error(uri, response)
      http_code = response.http_response.code.to_i
      message = response.http_response.message || Rack::Utils::HTTP_STATUS_CODES[http_code]

      error_result(
        "#{uri} endpoint error: #{http_code}#{message.presence&.prepend(' ')}",
        http_code
      )
    end

    def error_result(message, reason = nil)
      ServiceResponse.error(message: message, reason: reason)
    end

    def status_code_is_valid?(response)
      response.http_response.code == '200'
    end

    def content_type_is_valid?(response)
      response.http_response['content-type'] == EXPECTED_CONTENT_TYPE
    end

    def response_body_is_valid?(response_body)
      response_body.match?(GIT_BODY_MESSAGE_REGEXP)
    end
  end
end
