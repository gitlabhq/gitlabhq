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

    ViteRuby.configure(
      host: config.fetch('host', 'localhost'),
      port: Integer(config.fetch('port', 3038))
    )
  end

  def self.vite_gdk_config_path
    File.join(__dir__, '../config/vite.gdk.json')
  end
end
