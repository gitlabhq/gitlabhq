# frozen_string_literal: true

module Import
  class ValidateRemoteGitEndpointService
    # Validates if the remote endpoint is a valid GIT repository
    # Only smart protocol is supported
    # Validation rules are taken from https://git-scm.com/docs/http-protocol#_smart_clients

    GIT_SERVICE_NAME = "git-upload-pack"
    GIT_EXPECTED_FIRST_PACKET_LINE = "# service=#{GIT_SERVICE_NAME}"
    GIT_BODY_MESSAGE_REGEXP = /^[0-9a-f]{4}#{GIT_EXPECTED_FIRST_PACKET_LINE}/.freeze
    # https://github.com/git/git/blob/master/Documentation/technical/protocol-common.txt#L56-L59
    GIT_PROTOCOL_PKT_LEN = 4
    GIT_MINIMUM_RESPONSE_LENGTH = GIT_PROTOCOL_PKT_LEN + GIT_EXPECTED_FIRST_PACKET_LINE.length
    EXPECTED_CONTENT_TYPE = "application/x-#{GIT_SERVICE_NAME}-advertisement"

    def initialize(params)
      @params = params
    end

    def execute
      uri = Gitlab::Utils.parse_url(@params[:url])

      if !uri || !uri.hostname || Project::VALID_IMPORT_PROTOCOLS.exclude?(uri.scheme)
        return ServiceResponse.error(message: "#{@params[:url]} is not a valid URL")
      end

      return ServiceResponse.success if uri.scheme == 'git'

      uri.fragment = nil
      url = Gitlab::Utils.append_path(uri.to_s, "/info/refs?service=#{GIT_SERVICE_NAME}")

      response_body = ''
      result = nil
      Gitlab::HTTP.try_get(url, stream_body: true, follow_redirects: false, basic_auth: auth) do |fragment|
        response_body += fragment
        next if response_body.length < GIT_MINIMUM_RESPONSE_LENGTH

        result = if status_code_is_valid(fragment) && content_type_is_valid(fragment) && response_body_is_valid(response_body)
                   :success
                 else
                   :error
                 end

        # We are interested only in the first chunks of the response
        # So we're using stream_body: true and breaking when receive enough body
        break
      end

      if result == :success
        ServiceResponse.success
      else
        ServiceResponse.error(message: "#{uri} is not a valid HTTP Git repository")
      end
    end

    private

    def auth
      unless @params[:user].to_s.blank?
        {
          username: @params[:user],
          password: @params[:password]
        }
      end
    end

    def status_code_is_valid(fragment)
      fragment.http_response.code == '200'
    end

    def content_type_is_valid(fragment)
      fragment.http_response['content-type'] == EXPECTED_CONTENT_TYPE
    end

    def response_body_is_valid(response_body)
      response_body.match?(GIT_BODY_MESSAGE_REGEXP)
    end
  end
end
