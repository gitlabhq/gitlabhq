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
      headers: request.headers
    ).organization

    ::Current.organization = organization
  end
end
# rubocop:enable Gitlab/NamespacedClass
# rubocop:enable Rails/ApplicationController
