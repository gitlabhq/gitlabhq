# Protects OmniAuth request phase against CSRF.

module OmniAuth
  module RequestForgeryProtection
    class Controller < ActionController::Base
      protect_from_forgery with: :exception

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
  end
end
