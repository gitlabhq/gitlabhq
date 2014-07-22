class SessionsController < Devise::SessionsController

  def new
    redirect_url = if request.referer.present?
                     referer_uri = URI(request.referer)
                     if referer_uri.host == Gitlab.config.gitlab.host
                       referer_uri.path
                     else
                       request.fullpath
                     end
                   else
                     request.fullpath
                   end

    store_location_for(:redirect, redirect_url)

    super
  end

  def create
    super
  end
end
