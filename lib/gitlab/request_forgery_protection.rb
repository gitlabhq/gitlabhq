# A module to check CSRF tokens in requests.
# It's used in API helpers and OmniAuth.
# Usage: GitLab::RequestForgeryProtection.call(env)

module Gitlab
  module RequestForgeryProtection
    class Controller < ActionController::Base
      protect_from_forgery with: :exception

      rescue_from ActionController::InvalidAuthenticityToken do |e|
        logger.warn "This CSRF token verification failure is handled internally by `GitLab::RequestForgeryProtection`"
        logger.warn "Unlike the logs may suggest, this does not result in an actual 422 response to the user"
        logger.warn "For API requests, the only effect is that `current_user` will be `nil` for the duration of the request"

        raise e
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
      call(env)

      true
    rescue ActionController::InvalidAuthenticityToken
      false
    end
  end
end
