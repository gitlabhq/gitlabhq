# frozen_string_literal: true

module OmniAuth
  module Strategies
    class OAuth2
      alias_method :original_callback_phase, :callback_phase

      # Monkey patch until PR is merged and released upstream
      # https://github.com/omniauth/omniauth-oauth2/pull/129
      def callback_phase
        original_callback_phase
      rescue ::Faraday::TimeoutError, ::Faraday::ConnectionFailed => e
        fail!(:timeout, e)
      end
    end
  end
end
