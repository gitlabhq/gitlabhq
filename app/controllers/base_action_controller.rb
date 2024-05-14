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
      # Normally all Vite requests are proxied via Vite Ruby's middleware (example:
      # https://gdk.test:3000/vite-dev/@fs/path/to/your/gdk), unless the
      # skipProxy parameter is used (https://vite-ruby.netlify.app/config/#skipproxy-experimental).
      #
      # However, HMR requests go directly to another host, and we need to allow that.
      # We need both Websocket and HTTP URLs because Vite will attempt to ping
      # the HTTP URL if the Websocket isn't available:
      # https://github.com/vitejs/vite/blob/899d9b1d272b7057aafc6fa01570d40f288a473b/packages/vite/src/client/client.ts#L320-L327
      hmr_ws_url = Gitlab::Utils.append_path(helpers.vite_hmr_websocket_url, 'vite-dev/')
      hmr_http_url = Gitlab::Utils.append_path(helpers.vite_hmr_http_url, 'vite-dev/')
      http_path = Gitlab::Utils.append_path(Gitlab.config.gitlab.url, 'vite-dev/')

      connect_sources = p.directives['connect-src']
      p.connect_src(*(Array.wrap(connect_sources) | [hmr_ws_url, hmr_http_url]))

      worker_sources = p.directives['worker-src']
      p.worker_src(*(Array.wrap(worker_sources) | [hmr_ws_url, hmr_http_url, http_path]))
    end

    next unless Gitlab::CurrentSettings.snowplow_enabled? && !Gitlab::CurrentSettings.snowplow_collector_hostname.blank?

    default_connect_src = p.directives['connect-src'] || p.directives['default-src']
    connect_src_values = Array.wrap(default_connect_src) | [Gitlab::CurrentSettings.snowplow_collector_hostname]
    p.connect_src(*connect_src_values)
  end
end
# rubocop:enable Gitlab/NamespacedClass
# rubocop:enable Rails/ApplicationController
