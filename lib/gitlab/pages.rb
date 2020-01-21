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

      def access_control_is_forced?
        ::Gitlab.config.pages.access_control &&
          ::Gitlab::CurrentSettings.current_application_settings.force_pages_access_control
      end
    end
  end
end
