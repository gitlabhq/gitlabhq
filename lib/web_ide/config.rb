# frozen_string_literal: true

module WebIde
  #
  # Base GitLab WebIde Configuration facade
  #
  class Config
    ConfigError = Class.new(StandardError)

    def initialize(config, opts = {})
      @config = build_config(config, opts)

      @global = Entry::Global.new(@config,
        with_image_ports: true)
      @global.compose!
    rescue Gitlab::Config::Loader::FormatError => e
      raise Config::ConfigError, e.message
    end

    def valid?
      @global.valid?
    end

    def errors
      @global.errors
    end

    def to_hash
      @config
    end

    def terminal_value
      @global.terminal_value
    end

    def schemas_value
      @global.schemas_value
    end

    private

    def build_config(config, _opts = {})
      Gitlab::Config::Loader::Yaml.new(config).load!
    end
  end
end
