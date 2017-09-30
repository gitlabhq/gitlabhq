module GoogleApi
  class AuthorizationsController < ApplicationController
    def callback
      session[GoogleApi::CloudPlatform::Client.session_key_for_token] =
        GoogleApi::CloudPlatform::Client.new(nil, callback_google_api_authorizations_url)
                                        .get_token(params[:code])

      if params[:state]
        redirect_to params[:state]
      else
        redirect_to root_url
      end
    end
  end
end
