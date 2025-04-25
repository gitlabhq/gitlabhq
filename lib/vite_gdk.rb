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
    host = config['public_host'] || 'localhost'
    ViteRuby.env['VITE_HMR_HOST'] = host

    ViteRuby.configure(
      host: host,
      port: Integer(config['port'] || 3808),
      https: config.fetch('https', { 'enabled' => false })['enabled']
    )
  end

  def self.vite_gdk_config_path
    File.join(__dir__, '../config/vite.gdk.json')
  end
end
