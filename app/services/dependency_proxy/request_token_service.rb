# frozen_string_literal: true

module DependencyProxy
  class RequestTokenService < DependencyProxy::BaseService
    def initialize(image)
      @image = image
    end

    def execute
      response = Gitlab::HTTP.get(auth_url)

      if response.success?
        success(token: Gitlab::Json.parse(response.body)['token'])
      else
        error('Expected 200 response code for an access token', response.code)
      end
    rescue Timeout::Error => exception
      error(exception.message, 599)
    rescue JSON::ParserError
      error('Failed to parse a response body for an access token', 500)
    end

    private

    def auth_url
      registry.auth_url(@image)
    end
  end
end
