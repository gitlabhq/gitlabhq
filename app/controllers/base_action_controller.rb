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
  include CurrentOrganization

  content_security_policy do |p|
    next if p.directives.blank?
    next unless Gitlab::CurrentSettings.snowplow_enabled? && !Gitlab::CurrentSettings.snowplow_collector_hostname.blank?

    append_to_content_security_policy(p, 'connect-src', [Gitlab::CurrentSettings.snowplow_collector_hostname])
  end

  def append_to_content_security_policy(policy, directive, values)
    existing_value = policy.directives[directive] || policy.directives['default-src']
    new_value = Array.wrap(existing_value) | values
    policy.directives[directive] = new_value
  end
end
# rubocop:enable Gitlab/NamespacedClass
# rubocop:enable Rails/ApplicationController
