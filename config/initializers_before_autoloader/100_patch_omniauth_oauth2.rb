# frozen_string_literal: true

# See https://github.com/omniauth/omniauth-oauth2/blob/v1.7.1/lib/omniauth/strategies/oauth2.rb#L84-L101
# for the original version of this code.
#
# Note: We need to override `callback_phase` directly (instead of using a module with `include` or `prepend`),
# because the method has a `super` call which needs to go to the `OmniAuth::Strategy` module,
# and it also deletes `omniauth.state` from the session as a side effect.

module OmniAuth
  module Strategies
    class OAuth2
      def callback_phase
        error = request.params["error_reason"].presence || request.params["error"].presence
        # Monkey patch #1:
        #
        # Swap the order of these conditions around so the `state` param is verified *first*,
        # before using the error params returned by the provider.
        #
        # This avoids content spoofing attacks by crafting a URL with malicious messages,
        # because the `state` param is only present in the session after a valid OAuth2 authentication flow.
        if !options.provider_ignores_state && (request.params["state"].to_s.empty? || request.params["state"] != session.delete("omniauth.state"))
          fail!(:csrf_detected, CallbackError.new(:csrf_detected, "CSRF detected"))
        elsif error
          fail!(error, CallbackError.new(request.params["error"], request.params["error_description"].presence || request.params["error_reason"].presence, request.params["error_uri"]))
        else
          self.access_token = build_access_token
          self.access_token = access_token.refresh! if access_token.expired?
          super
        end
      rescue ::OAuth2::Error, CallbackError => e
        fail!(:invalid_credentials, e)
      rescue ::Timeout::Error, ::Errno::ETIMEDOUT => e
        fail!(:timeout, e)
      rescue ::SocketError => e
        fail!(:failed_to_connect, e)
      # Monkey patch #2:
      #
      # Also catch errors from Faraday.
      # See https://github.com/omniauth/omniauth-oauth2/pull/129
      # and https://github.com/oauth-xx/oauth2/issues/152
      #
      # This can be removed with https://gitlab.com/gitlab-org/gitlab/-/issues/340933
      rescue ::Faraday::TimeoutError, ::Faraday::ConnectionFailed => e
        fail!(:timeout, e)
      end
    end
  end
end
