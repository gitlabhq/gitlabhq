# frozen_string_literal: true

module ViteHelper
  def vite_enabled?
    # vite is not production ready yet
    return false if Rails.env.production?

    Gitlab::Utils.to_boolean(ViteRuby.env['VITE_ENABLED'], default: false)
  end

  def vite_hmr_websocket_url
    ViteRuby.env['VITE_HMR_WS_URL']
  end

  def vite_hmr_http_url
    ViteRuby.env['VITE_HMR_HTTP_URL']
  end
end
