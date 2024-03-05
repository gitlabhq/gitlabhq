# frozen_string_literal: true

module ViteGdk
  def self.load_gdk_vite_config
    # can't use Rails.env.production? here because this file is required outside of Gitlab app instance
    return if ENV['RAILS_ENV'] == 'production'

    return unless File.exist?(vite_gdk_config_path)

    config = YAML.safe_load_file(vite_gdk_config_path)
    enabled = config.fetch('enabled', false)
    # ViteRuby doesn't like if env vars aren't strings
    ViteRuby.env['VITE_ENABLED'] = enabled.to_s

    return unless enabled

    # From https://vitejs.dev/config/server-options
    host = config['host'] || 'localhost'
    port = Integer(config['port'] || 3808)
    hmr_config = config['hmr'] || {}
    hmr_host = hmr_config['host'] || host
    hmr_port = hmr_config['clientPort'] || hmr_config['port'] || port
    hmr_ws_protocol = hmr_config['protocol'] || 'ws'
    ViteRuby.env['VITE_HMR_HOST'] = hmr_host
    ViteRuby.env['VITE_HMR_WS_URL'] = "#{hmr_ws_protocol}://#{hmr_host}:#{hmr_port}"

    ViteRuby.configure(
      host: host,
      port: port
    )
  end

  def self.vite_gdk_config_path
    File.join(__dir__, '../config/vite.gdk.json')
  end
end
