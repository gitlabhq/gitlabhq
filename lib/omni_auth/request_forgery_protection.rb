# Protects OmniAuth request phase against CSRF.

module OmniAuth
  # Based on ActionController::RequestForgeryProtection.
  class RequestForgeryProtection
    def initialize(env)
      @env = env
    end

    def request
      @request ||= ActionDispatch::Request.new(@env)
    end

    def session
      request.session
    end

    def reset_session
      request.reset_session
    end

    def params
      request.params
    end

    def call
      verify_authenticity_token
    end

    def verify_authenticity_token
      if !verified_request?
        Rails.logger.warn "Can't verify CSRF token authenticity" if Rails.logger
        handle_unverified_request
      end
    end

    private

    def protect_against_forgery?
      ApplicationController.allow_forgery_protection
    end

    def request_forgery_protection_token
      ApplicationController.request_forgery_protection_token
    end

    def forgery_protection_strategy
      ApplicationController.forgery_protection_strategy
    end

    def verified_request?
      !protect_against_forgery? || request.get? || request.head? ||
        form_authenticity_token == params[request_forgery_protection_token] ||
        form_authenticity_token == request.headers['X-CSRF-Token']
    end

    def handle_unverified_request
      forgery_protection_strategy.new(self).handle_unverified_request
    end

    # Sets the token value for the current session.
    def form_authenticity_token
      session[:_csrf_token] ||= SecureRandom.base64(32)
    end
  end
end
