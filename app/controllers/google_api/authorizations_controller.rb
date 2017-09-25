module GoogleApi
  class AuthorizationsController < ApplicationController
    # callback_google_api_authorizations GET|POST /google_api/authorizations/callback(.:format)                                                        google_api/authorizations#callback
    ##
    # TODO: 
    # - Is it ok to use both "http://localhost:3000/google_api/authorizations/callback"(For login) and "http://localhost:3000/google_api/authorizations/callback"(For API token)
    def callback
      session[access_token_key] = api_client.get_token(params[:code])

      if params[:state]
        redirect_to params[:state]
      else
        redirect_to root_url
      end
    end

    def api_client
      @api_client ||=
        GoogleApi::Authentication.new(nil, callback_google_api_authorizations_url)
    end

    def access_token_key
      # :"#{api_client.scope}_access_token"
      :"hoge_access_token" # TODO: 
    end
  end
end
