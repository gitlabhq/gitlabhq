# frozen_string_literal: true

module GitlabSettings
  class Options
    # Recursively build GitlabSettings::Options
    def self.build(obj)
      case obj
      when Hash
        new(obj.transform_values { |value| build(value) })
      when Array
        obj.map { |value| build(value) }
      else
        obj
      end
    end

    def initialize(value)
      @options = value.deep_stringify_keys
    end

    def [](key)
      @options[key.to_s]
    end

    def []=(key, value)
      @options[key.to_s] = Options.build(value)
    end

    def key?(name)
      @options.key?(name.to_s) || @options.key?(name.to_sym)
    end
    alias_method :has_key?, :key?

    def to_hash
      @options.deep_transform_values do |option|
        case option
        when GitlabSettings::Options
          option.to_hash
        else
          option
        end
      end
    end
    alias_method :to_h, :to_hash

    def merge(other)
      Options.build(to_hash.merge(other.deep_stringify_keys))
    end

    def deep_merge(other)
      Options.build(to_hash.deep_merge(other.deep_stringify_keys))
    end

    def is_a?(klass)
      return true if klass == Hash

      super(klass)
    end

    def method_missing(name, *args, &block)
      name_string = +name.to_s

      if name_string.chomp!("=")
        return self[name_string] = args.first if key?(name_string)
      elsif key?(name_string)
        return self[name_string]
      end

      return @options.public_send(name, *args, &block) if @options.respond_to?(name) # rubocop: disable GitlabSecurity/PublicSend

      raise ::GitlabSettings::MissingSetting, "option '#{name}' not defined"
    end

    def respond_to_missing?(name, include_all = false)
      return true if key?(name)

      @options.respond_to?(name, include_all)
    end
  end
end
