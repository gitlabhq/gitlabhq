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
      return_to = oauth.get_oauth_state_return_to
      redirect_to(return_to || root_path)
    else
      invalid_credentials
    end
  end

  private

  def undefined_oauth_application
    @error = 'There is no OAuth application defined for this Geo node.'
    render :error, layout: 'errors'
  end
end
