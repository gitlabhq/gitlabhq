# frozen_string_literal: true

module DependencyProxy
  class PullManifestService < DependencyProxy::BaseService
    def initialize(image, tag, token)
      @image = image
      @tag = tag
      @token = token
    end

    def execute
      response = Gitlab::HTTP.get(manifest_url, headers: auth_headers)

      if response.success?
        success(manifest: response.body)
      else
        error(response.body, response.code)
      end
    rescue Timeout::Error => exception
      error(exception.message, 599)
    end

    private

    def manifest_url
      registry.manifest_url(@image, @tag)
    end
  end
end
