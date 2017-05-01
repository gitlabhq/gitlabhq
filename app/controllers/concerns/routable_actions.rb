module RoutableActions
  extend ActiveSupport::Concern

  def ensure_canonical_path(routable, requested_path)
    return unless request.get?

    if routable.full_path != requested_path
      redirect_to request.original_url.sub(requested_path, routable.full_path)
    end
  end
end
