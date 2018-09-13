class Oauth::GeoAuthController < ActionController::Base
  rescue_from Gitlab::Geo::OauthApplicationUndefinedError, with: :undefined_oauth_application
  rescue_from OAuth2::Error, with: :auth

  def auth
    oauth = Gitlab::Geo::OauthSession.new(state: params[:state])
    unless oauth.oauth_state_valid?
      redirect_to root_url
      return
    end

    redirect_to oauth.authorize_url(redirect_uri: oauth_geo_callback_url, state: params[:state])
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def callback
    oauth = Gitlab::Geo::OauthSession.new(state: params[:state])
    unless oauth.oauth_state_valid?
      redirect_to new_user_session_path
      return
    end

    token = oauth.get_token(params[:code], redirect_uri: oauth_geo_callback_url)
    remote_user = oauth.authenticate_with_gitlab(token)

    user = User.find_by(id: remote_user['id'])

    if user && sign_in(user, bypass: true)
      after_sign_in_with_gitlab(token, oauth.get_oauth_state_return_to)
    else
      invalid_credentials
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def logout
    logout = Oauth2::LogoutTokenValidationService.new(current_user, params)
    result = logout.execute
    if result[:status] == :success
      sign_out current_user
      redirect_to root_path
    else
      access_token_error(result[:message])
    end
  end

  private

  def after_sign_in_with_gitlab(token, return_to)
    session[:access_token] = token
    redirect_to(return_to || root_path)
  end

  def invalid_credentials
    @error = 'Cannot find user to login. Your account may have been deleted.'
    render :error, layout: 'errors'
  end

  def undefined_oauth_application
    @error = 'There are no OAuth application defined for this Geo node. Please ask your administrator to visit "Geo Nodes" on admin screen and click on "Repair authentication".'
    render :error, layout: 'errors'
  end

  def access_token_error(status)
    @error = "There is a problem with the OAuth access_token: #{status}"
    render :error, layout: 'errors'
  end
end
