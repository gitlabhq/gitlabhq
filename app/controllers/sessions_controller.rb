class SessionsController < Devise::SessionsController

  def new
    if request.referer.present?
      store_location_for(:redirect, URI(request.referer).path)
    end

    super
  end

  def create
    super
  end
end
