# frozen_string_literal: true

class DependencyProxy::Registry
  AUTH_URL = 'https://auth.docker.io'
  LIBRARY_URL = 'https://registry-1.docker.io/v2'
  PROXY_AUTH_URL = Gitlab::Utils.append_path(Gitlab.config.gitlab.url, "jwt/auth")

  class << self
    def auth_url(image)
      "#{AUTH_URL}/token?service=registry.docker.io&scope=repository:#{image_path(image)}:pull"
    end

    def manifest_url(image, tag)
      "#{LIBRARY_URL}/#{image_path(image)}/manifests/#{tag}"
    end

    def blob_url(image, blob_sha)
      "#{LIBRARY_URL}/#{image_path(image)}/blobs/#{blob_sha}"
    end

    def authenticate_header
      "Bearer realm=\"#{PROXY_AUTH_URL}\",service=\"#{::Auth::DependencyProxyAuthenticationService::AUDIENCE}\""
    end

    private

    def image_path(image)
      if image.include?('/')
        image
      else
        "library/#{image}"
      end
    end
  end
end

::DependencyProxy::Registry.prepend_mod
