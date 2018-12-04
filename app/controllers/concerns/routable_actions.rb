# frozen_string_literal: true

module RoutableActions
  extend ActiveSupport::Concern

  def find_routable!(routable_klass, requested_full_path, extra_authorization_proc: nil, not_found_or_authorized_proc: nil)
    routable = routable_klass.find_by_full_path(requested_full_path, follow_redirects: request.get?)
    if routable_authorized?(routable, extra_authorization_proc)
      ensure_canonical_path(routable, requested_full_path)
      routable
    else
      if not_found_or_authorized_proc
        not_found_or_authorized_proc.call(routable)
      end

      route_not_found unless performed?

      nil
    end
  end

  def routable_authorized?(routable, extra_authorization_proc)
    return false unless routable

    action = :"read_#{routable.class.to_s.underscore}"
    return false unless can?(current_user, action, routable)

    if extra_authorization_proc
      extra_authorization_proc.call(routable)
    else
      true
    end
  end

  def ensure_canonical_path(routable, requested_full_path)
    return unless request.get?

    canonical_path = routable.full_path
    if canonical_path != requested_full_path
      if canonical_path.casecmp(requested_full_path) != 0
        flash[:notice] = "#{routable.class.to_s.titleize} '#{requested_full_path}' was moved to '#{canonical_path}'. Please update any links and bookmarks that may still have the old path."
      end

      redirect_to build_canonical_path(routable)
    end
  end
end
