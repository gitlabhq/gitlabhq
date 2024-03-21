# frozen_string_literal: true

# A module to check CSRF tokens in requests.
# It's used in API helpers and OmniAuth.
# Usage: GitLab::RequestForgeryProtection.call(env)

module Gitlab
  module RequestForgeryProtection
    class Controller < BaseActionController
      protect_from_forgery with: :exception, prepend: true

      def initialize
        super

        # Squelch noisy and unnecessary "Can't verify CSRF token authenticity." messages.
        # X-Csrf-Token is only one authentication mechanism for API helpers.
        self.logger = ActiveSupport::Logger.new(File::NULL)
      end

      def index
        head :ok
      end
    end

    def self.app
      @app ||= Controller.action(:index)
    end

    def self.call(env)
      app.call(env)
    end

    def self.verified?(env)
      minimal_env = env.slice('REQUEST_METHOD', 'rack.session', 'HTTP_X_CSRF_TOKEN')
                      .merge('rack.input' => '')

      # The CSRF token for some requests is in the form instead of headers.
      # This line of code is used to accommodate this situation. See: https://gitlab.com/gitlab-org/gitlab/-/issues/443398
      minimal_env['HTTP_X_CSRF_TOKEN'] ||= Rack::Request.new(env.dup).params['authenticity_token']

      call(minimal_env)

      true
    rescue ActionController::InvalidAuthenticityToken
      false
    end
  end
end
