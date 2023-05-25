# frozen_string_literal: true

module GitlabSettings
  class Settings
    attr_reader :source

    def initialize(source, section)
      raise(ArgumentError, 'config source is required') if source.blank?
      raise(ArgumentError, 'config section is required') if section.blank?

      # Rails will set the default encoding to UTF-8
      # (https://github.com/rails/rails/blob/v6.1.7.2/railties/lib/rails.rb#L21C1-L24),
      # but it's possible this class is used before `require 'rails'` is
      # called, as in the case of `sidekiq-cluster`. Ensure the
      # configuration file is parsed as UTF-8, or
      # ActiveSupport::ConfigurationFile.parse will blow up if the
      # configuration file contains UTF-8 characters.
      Encoding.default_external = Encoding::UTF_8
      Encoding.default_internal = Encoding::UTF_8

      @source = source
      @section = section
      @loaded = false
    end

    def reload!
      yaml = ActiveSupport::ConfigurationFile.parse(source)
      all_configs = yaml.deep_stringify_keys
      configs = all_configs[section]

      @config = Options.build(configs).tap do
        @loaded = true
      end
    end

    def method_missing(name, *args)
      reload! unless @loaded

      config.public_send(name, *args) # rubocop: disable GitlabSecurity/PublicSend
    end

    def respond_to_missing?(name, include_all = false)
      config.respond_to?(name, include_all)
    end

    private

    attr_reader :config, :section
  end
end
