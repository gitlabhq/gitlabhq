# frozen_string_literal: true

module DependencyProxy
  class HeadManifestService < DependencyProxy::BaseService
    ACCEPT_HEADERS = DependencyProxy::Manifest::ACCEPTED_TYPES.join(',')

    def initialize(image, tag, token)
      @image = image
      @tag = tag
      @token = token
    end

    def execute
      response = Gitlab::HTTP.head(manifest_url, headers: auth_headers.merge(Accept: ACCEPT_HEADERS))

      if response.success?
        success(
          digest: response.headers[DependencyProxy::Manifest::DIGEST_HEADER],
          content_type: response.headers['content-type']
        )
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
