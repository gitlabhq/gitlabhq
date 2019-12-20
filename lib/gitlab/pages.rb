# frozen_string_literal: true

module Gitlab
  class Pages
    VERSION = File.read(Rails.root.join("GITLAB_PAGES_VERSION")).strip.freeze
    INTERNAL_API_REQUEST_HEADER = 'Gitlab-Pages-Api-Request'.freeze
    MAX_SIZE = 1.terabyte

    include JwtAuthenticatable

    class << self
      def verify_api_request(request_headers)
        decode_jwt_for_issuer('gitlab-pages', request_headers[INTERNAL_API_REQUEST_HEADER])
      rescue JWT::DecodeError
        false
      end

      def secret_path
        Gitlab.config.pages.secret_file
      end
    end
  end
end
