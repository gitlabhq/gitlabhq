module RoutableActions
  extend ActiveSupport::Concern

  def find_routable!(routable_klass, requested_full_path, extra_authorization_method: nil)
    routable = routable_klass.find_by_full_path(requested_full_path, follow_redirects: request.get?)

    if authorized?(routable_klass, routable, extra_authorization_method)
      ensure_canonical_path(routable, requested_full_path)
      routable
    else
      route_not_found
      nil
    end
  end

  def authorized?(routable_klass, routable, extra_authorization_method)
    action = :"read_#{routable_klass.to_s.underscore}"
    return false unless can?(current_user, action, routable)

    if extra_authorization_method
      send(extra_authorization_method, routable)
    else
      true
    end
  end

  def ensure_canonical_path(routable, requested_path)
    return unless request.get?

    canonical_path = routable.try(:full_path) || routable.namespace.full_path
    if canonical_path != requested_path
      flash[:notice] = 'This project has moved to this location. Please update your links and bookmarks.'
      redirect_to request.original_url.sub(requested_path, canonical_path)
    end
  end
end
