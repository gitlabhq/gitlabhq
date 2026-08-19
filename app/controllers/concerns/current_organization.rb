# frozen_string_literal: true

module CurrentOrganization
  extend ActiveSupport::Concern
  include Gitlab::Utils::StrongMemoize

  def set_current_organization
    return if ::Current.organization_assigned

    ::Current.organization = current_organization_resolver.organization
  end

  # Responds exactly like a nonexistent path, so it does not reveal whether
  # the group/namespace in the URL exists.
  def verify_organization_path!
    return unless current_organization_resolver.organization_path_mismatch?

    route_not_found
  end

  # Shared with CurrentDataContext#set_data_context so the request's anchor
  # (params/headers, including its DB queries) isn't resolved twice on the
  # same request now that both before_actions run unconditionally.
  def current_organization_resolver
    Gitlab::Current::Organization.new(
      params: organization_params,
      user: current_user,
      rack_env: request.env
    )
  end
  strong_memoize_attr :current_organization_resolver
end
