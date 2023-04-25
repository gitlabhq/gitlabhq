# frozen_string_literal: true

module GitlabSettings
  class Settings
    attr_reader :source

    def initialize(source, section)
      raise(ArgumentError, 'config source is required') if source.blank?
      raise(ArgumentError, 'config section is required') if section.blank?

      @source = source
      @section = section

      reload!
    end

    def reload!
      yaml = ActiveSupport::ConfigurationFile.parse(source)
      all_configs = yaml.deep_stringify_keys
      configs = all_configs[section]

      @config = Options.build(configs)
    end

    def method_missing(name, *args)
      config.public_send(name, *args) # rubocop: disable GitlabSecurity/PublicSend
    end

    def respond_to_missing?(name, include_all = false)
      config.respond_to?(name, include_all)
    end

    private

    attr_reader :config, :section
  end
end
