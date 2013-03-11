class SessionsController < Devise::SessionsController

  def new
    if Gitlab.config.omniauth.openid_sso.enabled
      redirect_to omniauth_authorize_path(User, :openid), status: :moved_permanently
    else
      super
    end
  end

end
