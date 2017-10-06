module GoogleApi
  class AuthorizationsController < ApplicationController
    def callback
      token, expires_at = GoogleApi::CloudPlatform::Client
        .new(nil, callback_google_api_auth_url)
        .get_token(params[:code])

      session[GoogleApi::CloudPlatform::Client.session_key_for_token] = token
      session[GoogleApi::CloudPlatform::Client.session_key_for_expires_at] =
        expires_at.to_s

      key, _ = GoogleApi::CloudPlatform::Client
        .session_key_for_second_redirect_uri(secure: params[:state])

      second_redirect_uri = session[key]

      if second_redirect_uri.present?
        redirect_to second_redirect_uri
      else
        redirect_to root_path
      end
    end
  end
end
