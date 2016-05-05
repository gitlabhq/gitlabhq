class Oauth::GeoAuthController < ActionController::Base
  rescue_from Gitlab::Geo::OauthApplicationUndefinedError, with: :undefined_oauth_application
  rescue_from OAuth2::Error, with: :auth

  def auth
    oauth = Gitlab::Geo::OauthSession.new(state: params[:state])
    unless oauth.is_oauth_state_valid?
      redirect_to root_url
      return
    end

    redirect_to oauth.authorize_url(redirect_uri: oauth_geo_callback_url, state: params[:state])
  end

  def callback
    oauth = Gitlab::Geo::OauthSession.new(state: params[:state])
    unless oauth.is_oauth_state_valid?
      redirect_to new_user_sessions_path
      return
    end

    token = oauth.get_token(params[:code], redirect_uri: oauth_geo_callback_url)
    remote_user = oauth.authenticate_with_gitlab(token)

    user = User.find(remote_user['id'])

    if user && sign_in(user, bypass: true)
      session[:access_token] = token
      return_to = oauth.get_oauth_state_return_to
      redirect_to(return_to || root_path)
    else
      invalid_credentials
    end
  end

  def logout
    oauth = Gitlab::Geo::OauthSession.new(state: params[:state])
    access_token = oauth.extract_logout_token
    access_token_status = Oauth2::AccessTokenValidationService.validate(access_token)

    if access_token_status == Oauth2::AccessTokenValidationService::VALID
      user = User.find(access_token.resource_owner_id)

      if current_user == user
        sign_out current_user
      end
    else

    end

    redirect_to root_path
  end

  private

  def undefined_oauth_application
    @error = 'There are no OAuth application defined for this Geo node. Please ask your administrator to visit "Geo Nodes" on admin screen and click on "Repair authentication".'
    render :error, layout: 'errors'
  end

  def access_token_error(status)
    @error = "There is a problem with the OAuth access_token: #{status}"
    render :error, layout: 'errors'
  end
end
