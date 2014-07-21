class SessionsController < Devise::SessionsController

  def new
    if request.referer.present?
      referer_uri = URI(request.referer)
      if referer_uri.host == Gitlab.config.gitlab.host
        store_location_for(:redirect, referer_uri.path)
      else
        store_location_for(:redirect, request.fullpath)
      end
    else
      store_location_for(:redirect, request.fullpath)
    end

    super
  end

  def create
    super
  end
end
