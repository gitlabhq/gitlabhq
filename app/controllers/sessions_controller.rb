class SessionsController < Devise::SessionsController

  def new
    redirect_path = if request.referer.present? && (params['redirect_to_referer'] == 'yes')
                     referer_uri = URI(request.referer)
                     if referer_uri.host == Gitlab.config.gitlab.host
                       referer_uri.path
                     else
                       request.fullpath
                     end
                   else
                     request.fullpath
                   end

    # Prevent a 'you are already signed in' message directly after signing:
    # we should never redirect to '/users/sign_in' after signing in successfully.
    unless redirect_path == '/users/sign_in'
      store_location_for(:redirect, redirect_path)
    end

    super
  end

  def create
    super
  end
end
