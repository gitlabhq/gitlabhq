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

    if helpers.vite_enabled?
      vite_port = ViteRuby.instance.config.port
      vite_origin = "#{Gitlab.config.gitlab.host}:#{vite_port}"
      http_origin = "http://#{vite_origin}"
      ws_origin = "ws://#{vite_origin}"
      wss_origin = "wss://#{vite_origin}"
      gitlab_ws_origin = Gitlab::Utils.append_path(Gitlab.config.gitlab.url, 'vite-dev/')
      http_path = Gitlab::Utils.append_path(http_origin, 'vite-dev/')

      connect_sources = p.directives['connect-src']
      p.connect_src(*(Array.wrap(connect_sources) | [ws_origin, wss_origin, http_path]))

      worker_sources = p.directives['worker-src']
      p.worker_src(*(Array.wrap(worker_sources) | [gitlab_ws_origin, http_path]))
    end

    next unless Gitlab::CurrentSettings.snowplow_enabled? && !Gitlab::CurrentSettings.snowplow_collector_hostname.blank?

    default_connect_src = p.directives['connect-src'] || p.directives['default-src']
    connect_src_values = Array.wrap(default_connect_src) | [Gitlab::CurrentSettings.snowplow_collector_hostname]
    p.connect_src(*connect_src_values)
  end
end
# rubocop:enable Gitlab/NamespacedClass
# rubocop:enable Rails/ApplicationController
