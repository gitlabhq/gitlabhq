# frozen_string_literal: true

# GitLab lightweight base action controller
#
# This class should be limited to content that
# is desired/required for *all* controllers in
# GitLab.
#
# Most controllers inherit from `ApplicationController`.
# Some controllers don't want or need all of that
# logic and instead inherit from `ActionController::Base`.
# This makes it difficult to set security headers and
# handle other critical logic across *all* controllers.
#
# Between this controller and `ApplicationController`
# no controller should ever inherit directly from
# `ActionController::Base`
#
# rubocop:disable Rails/ApplicationController -- This class is specifically meant as a base class for controllers that
# don't inherit from ApplicationController
# rubocop:disable Gitlab/NamespacedClass -- Base controllers live in the global namespace
class BaseActionController < ActionController::Base
  extend ContentSecurityPolicyPatch

  content_security_policy do |p|
    next if p.directives.blank?
    next unless Gitlab::CurrentSettings.snowplow_enabled? && !Gitlab::CurrentSettings.snowplow_collector_hostname.blank?

    default_connect_src = p.directives['connect-src'] || p.directives['default-src']
    connect_src_values = Array.wrap(default_connect_src) | [Gitlab::CurrentSettings.snowplow_collector_hostname]
    p.connect_src(*connect_src_values)
  end

  def set_current_organization
    return if ::Current.organization_assigned

    organization = Gitlab::Current::Organization.new(
      params: organization_params,
      user: current_user,
      session: session,
      headers: request.headers
    ).organization

    store_organization_in_session!(organization)

    ::Current.organization = organization
  end

  private

  def store_organization_in_session!(organization)
    # rubocop:disable Gitlab/FeatureFlagWithoutActor -- Cannot guarantee an actor is available here
    return unless Feature.enabled?(:set_current_organization_from_session)
    # rubocop:enable Gitlab/FeatureFlagWithoutActor

    return unless organization
    return unless request.format.html?

    session_key = Gitlab::Current::Organization::SESSION_KEY
    return if session[session_key] == organization.id

    session[session_key] = organization.id
  end
end
# rubocop:enable Gitlab/NamespacedClass
# rubocop:enable Rails/ApplicationController
