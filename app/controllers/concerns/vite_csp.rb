# frozen_string_literal: true

module ViteCSP
  extend ActiveSupport::Concern

  included do
    content_security_policy_with_context do |p|
      next unless helpers.vite_enabled?
      next if p.directives.blank?

      # We need both Websocket and HTTP URLs because Vite will attempt to ping
      # the HTTP URL if the Websocket isn't available:
      # https://github.com/vitejs/vite/blob/899d9b1d272b7057aafc6fa01570d40f288a473b/packages/vite/src/client/client.ts#L320-L327
      hmr_ws_url = Gitlab::Utils.append_path(helpers.vite_hmr_ws_origin, 'vite-dev/')
      http_path = Gitlab::Utils.append_path(helpers.vite_origin, 'vite-dev/')

      # http_path is used for openInEditorHost feature
      # https://devtools.vuejs.org/getting-started/open-in-editor#customize-request
      p.connect_src(*(Array.wrap(p.directives['connect-src']) | [hmr_ws_url, http_path]))
      p.worker_src(*(Array.wrap(p.directives['worker-src']) | [http_path]))
      p.style_src(*(Array.wrap(p.directives['style-src']) | [http_path]))
      p.font_src(*(Array.wrap(p.directives['font-src']) | [http_path]))
    end
  end
end
