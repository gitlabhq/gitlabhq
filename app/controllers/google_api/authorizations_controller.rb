module GoogleApi
  class AuthorizationsController < ApplicationController
    def callback
      token, expires_at = GoogleApi::CloudPlatform::Client
        .new(nil, callback_google_api_authorizations_url)
        .get_token(params[:code])

      session[GoogleApi::CloudPlatform::Client.session_key_for_token] = token
      session[GoogleApi::CloudPlatform::Client.session_key_for_expires_at] =
        expires_at.to_s

      if params[:state]
        redirect_to params[:state]
      else
        redirect_to root_url
      end
    end
  end
end
