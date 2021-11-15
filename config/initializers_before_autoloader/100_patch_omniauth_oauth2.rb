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
      alias_method :original_callback_phase, :callback_phase

      def callback_phase
        original_callback_phase
      # Monkey patch #1:
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
