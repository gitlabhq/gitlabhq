module RoutableActions
  extend ActiveSupport::Concern

  def ensure_canonical_path(routable, requested_path)
    return unless request.get?

    if routable.full_path != requested_path
      flash[:notice] = 'This project has moved to this location. Please update your links and bookmarks.'
      redirect_to request.original_url.sub(requested_path, routable.full_path)
    end
  end
end
