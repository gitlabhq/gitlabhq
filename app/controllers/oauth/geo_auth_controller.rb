class Oauth::GeoAuthController < ActionController::Base

  def auth
    oauth = Geo::OauthSession.new(state: params[:state])
    unless oauth.is_oauth_state_valid?
      redirect_to root_url
      return
    end

    redirect_to oauth.authorize_url(redirect_uri: oauth_geo_callback_url, state: params[:state])
  end

  def callback
    oauth = Geo::OauthSession.new(state: params[:state])
    unless oauth.is_oauth_state_valid?
      redirect_to new_user_sessions_path
      return
    end

    token = oauth.get_token(params[:code], redirect_uri: oauth_geo_callback_url)
    remote_user = oauth.authenticate(access_token: token)

    user = User.find(remote_user['id'])

    if user && sign_in(user)
      return_to = oauth.get_oauth_state_return_to
      redirect_to(return_to || root_path)
    else
      @error = 'Invalid credentials'
      render :new
    end
  end

end
