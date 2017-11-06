module GoogleApi
  class AuthorizationsController < ApplicationController
    def callback
      token, expires_at = GoogleApi::CloudPlatform::Client
        .new(nil, callback_google_api_auth_url)
        .get_token(params[:code])

      session[GoogleApi::CloudPlatform::Client.session_key_for_token] = token
      session[GoogleApi::CloudPlatform::Client.session_key_for_expires_at] =
        expires_at.to_s

      state_redirect_uri = redirect_uri_from_session_key(params[:state])

      if state_redirect_uri
        redirect_to state_redirect_uri
      else
        redirect_to root_path
      end
    end

    private

    def redirect_uri_from_session_key(state)
      key = GoogleApi::CloudPlatform::Client
        .session_key_for_redirect_uri(params[:state])
      session[key] if key
    end
  end
end
