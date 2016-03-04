class Oauth::GeoAuthController < ActionController::Base
  # skip_before_action :authenticate_user!

  def auth
    oauth = Geo::OauthSession.new(state: params[:state])
    unless oauth.is_oauth_state_valid?
      redirect_to root_url
      return
    end

    redirect_to client.auth_code.authorize_url({
                                                 redirect_uri: oauth_geo_callback_url,
                                                 state: params[:state]
                                               })
  end

  def callback
    oauth = Geo::OauthSession.new(state: params[:state])
    unless oauth.is_oauth_state_valid?
      redirect_to new_user_sessions_path
      return
    end

    token = client.auth_code.get_token(params[:code], redirect_uri: oauth_geo_callback_url).token

    @user_session = ::Geo::User.new(state: params[:state])
    remote_user = @user_session.authenticate(access_token: token)

    user = User.find(remote_user['id'])

    if user && sign_in(user)
      return_to = @user_session.get_oauth_state_return_to
      redirect_to(return_to || root_path)
    else
      @error = 'Invalid credentials'
      render :new
    end
  end

  private

  def client
    app = Gitlab::Geo.oauth_authentication
    @client ||= ::OAuth2::Client.new(
      app.uid,
      app.secret,
      {
        site: Gitlab::Geo.primary_node.url,
        authorize_url: 'oauth/authorize',
        token_url: 'oauth/token'
      }
    )
  end
end
