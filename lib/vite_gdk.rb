# frozen_string_literal: true

module ViteGdk
  def self.load_gdk_vite_config
    # can't use Rails.env.production? here because this file is required outside of Gitlab app instance
    return if ENV['RAILS_ENV'] == 'production'

    if File.exist?(vite_gdk_config_path)
      load_config_from_file
    elsif ENV.key?('VITE_ENABLED')
      # Non-GDK setups (e.g. Caproni) enable Vite via env vars instead of the file
      load_config_from_env
    end
  end

  def self.load_config_from_file
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

  def self.load_config_from_env
    enabled = ENV['VITE_ENABLED'] == 'true'
    # ViteRuby doesn't like if env vars aren't strings
    ViteRuby.env['VITE_ENABLED'] = enabled.to_s

    return unless enabled

    host = ENV['VITE_HMR_HOST'] || 'localhost'
    ViteRuby.env['VITE_HMR_HOST'] = host

    # Non-GDK setups (e.g. Caproni) use ViteRuby's defaults for port and HTTPS.
    ViteRuby.configure(host: host)
  end

  def self.vite_gdk_config_path
    File.join(__dir__, '../config/vite.gdk.json')
  end

  private_class_method :load_config_from_file, :load_config_from_env, :vite_gdk_config_path
end
