# frozen_string_literal: true

module RoutableActions
  extend ActiveSupport::Concern

  def find_routable!(routable_klass, routable_full_path, full_path, extra_authorization_proc: nil)
    routable = routable_klass.find_by_full_path(routable_full_path, follow_redirects: request.get?)
    if routable_authorized?(routable, extra_authorization_proc)
      ensure_canonical_path(routable, routable_full_path)
      routable
    else
      perform_not_found_actions(routable, not_found_actions, full_path)

      route_not_found unless performed?

      nil
    end
  end

  def not_found_actions
    [ProjectUnauthorized::ControllerActions.on_routable_not_found]
  end

  def perform_not_found_actions(routable, actions, full_path)
    actions.each do |action|
      break if performed?

      instance_exec(routable, full_path, &action)
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

  def ensure_canonical_path(routable, routable_full_path)
    return unless request.get?

    canonical_path = routable.full_path
    return unless canonical_path != routable_full_path

    if !request.xhr? && request.format.html? && canonical_path.casecmp(routable_full_path) != 0
      flash[:notice] =
        <<~HEREDOC.squish
        #{routable.class.to_s.titleize} '#{routable_full_path}' was moved to '#{canonical_path}'.
        Please update any links and bookmarks that may still have the old path.
        HEREDOC
    end

    redirect_to build_canonical_path(routable), status: :moved_permanently
  rescue ActionController::UrlGenerationError
    route_not_found
  end
end

RoutableActions.prepend_mod_with('RoutableActions')
