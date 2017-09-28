module GoogleApi
  class AuthorizationsController < ApplicationController
    def callback
      session[GoogleApi::CloudPlatform::Client.token_in_session] = 
        GoogleApi::Authentication.new(nil, callback_google_api_authorizations_url)
                                 .get_token(params[:code])

      if params[:state]
        redirect_to params[:state]
      else
        redirect_to root_url
      end
    end
  end
end
