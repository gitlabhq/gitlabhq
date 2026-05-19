# frozen_string_literal: true

require 'omniauth_openid_connect'

# rubocop:disable Gitlab/BoundedContexts -- OmniAuth is external middleware, not a GitLab bounded context
module OmniAuth
  module Strategies
    # Extends OpenIDConnect for the Cells architecture, where the OAuth callback
    # may arrive at a different cell than the one that initiated the request.
    # Session-based CSRF state is therefore unreliable; we bind the state to the
    # browser via a short-lived cookie instead.
    class CellsAwareOpenidConnect < OpenIDConnect
      OAUTH_STATE_COOKIE_NAME = 'omniauth_oauth_state'
      # Matches the IAM Auth Service parked-session TTL.
      OAUTH_STATE_COOKIE_MAX_AGE = 600

      def request_phase
        status, headers, body = super

        state_value = session['omniauth.state']
        set_oauth_state_cookie(headers, state_value)

        [status, headers, body]
      end

      def callback_phase
        return fail_with_csrf_error! unless valid_oauth_state_cookie?

        @pending_cookie_clear = true
        super
      end

      def call_app!(env = @env)
        status, headers, body = super
        clear_oauth_state_cookie(headers) if @pending_cookie_clear
        [status, headers, body]
      end

      # Override user_info method to handle IAM authentication service limitations
      # This is overridden from https://github.com/omniauth/omniauth_openid_connect/blob/master/lib/omniauth/strategies/openid_connect.rb#L263C6-L273C10
      # We skip the OIDC userinfo endpoint call and directly use the ID token for user information
      # when the userinfo endpoint is not available in the IAM authentication service
      def user_info
        return @user_info if @user_info

        if access_token.id_token
          decoded = decode_id_token(access_token.id_token).raw_attributes
          @user_info = ::OpenIDConnect::ResponseObject::UserInfo.new decoded
        else
          @user_info = access_token.userinfo!
        end
      end

      private

      def valid_oauth_state_cookie?
        cookie_value = request.cookies[OAUTH_STATE_COOKIE_NAME]
        return false if cookie_value.blank?

        state_param = request.params['state']
        return false unless state_param.is_a?(String) && state_param.present?

        ::Rack::Utils.secure_compare(cookie_value, state_param)
      end

      def set_oauth_state_cookie(headers, state_value)
        ::Rack::Utils.set_cookie_header!(headers, OAUTH_STATE_COOKIE_NAME,
          value: state_value,
          path: '/',
          httponly: true,
          same_site: :lax,
          max_age: OAUTH_STATE_COOKIE_MAX_AGE,
          secure: Gitlab.config.gitlab.https
        )
      end

      def clear_oauth_state_cookie(headers)
        ::Rack::Utils.delete_cookie_header!(headers, OAUTH_STATE_COOKIE_NAME, path: '/')
      end

      def fail_with_csrf_error!
        Gitlab::AppLogger.warn(message: 'OAuth state cookie validation failed', class_name: self.class.name)
        status, headers, body = fail!(:csrf_detected,
          CallbackError.new(error: :csrf_detected, reason: 'oauth_state cookie missing or mismatched'))
        clear_oauth_state_cookie(headers)
        [status, headers, body]
      end
    end
  end
end
# rubocop:enable Gitlab/BoundedContexts
