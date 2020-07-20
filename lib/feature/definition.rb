# frozen_string_literal: true

class Feature
  class Definition
    include ::Feature::Shared

    attr_reader :path
    attr_reader :attributes

    PARAMS.each do |param|
      define_method(param) do
        attributes[param]
      end
    end

    def initialize(path, opts = {})
      @path = path
      @attributes = {}

      # assign nil, for all unknown opts
      PARAMS.each do |param|
        @attributes[param] = opts[param]
      end
    end

    def key
      name.to_sym
    end

    def validate!
      unless name.present?
        raise Feature::InvalidFeatureFlagError, "Feature flag is missing name"
      end

      unless path.present?
        raise Feature::InvalidFeatureFlagError, "Feature flag '#{name}' is missing path"
      end

      unless type.present?
        raise Feature::InvalidFeatureFlagError, "Feature flag '#{name}' is missing type. Ensure to update #{path}"
      end

      unless Definition::TYPES.include?(type.to_sym)
        raise Feature::InvalidFeatureFlagError, "Feature flag '#{name}' type '#{type}' is invalid. Ensure to update #{path}"
      end

      unless File.basename(path, ".yml") == name
        raise Feature::InvalidFeatureFlagError, "Feature flag '#{name}' has an invalid path: '#{path}'. Ensure to update #{path}"
      end

      unless File.basename(File.dirname(path)) == type
        raise Feature::InvalidFeatureFlagError, "Feature flag '#{name}' has an invalid type: '#{path}'. Ensure to update #{path}"
      end

      if default_enabled.nil?
        raise Feature::InvalidFeatureFlagError, "Feature flag '#{name}' is missing default_enabled. Ensure to update #{path}"
      end
    end

    def valid_usage!(type_in_code:, default_enabled_in_code:)
      unless Array(type).include?(type_in_code.to_s)
        # Raise exception in test and dev
        raise Feature::InvalidFeatureFlagError, "The `type:` of `#{key}` is not equal to config: " \
          "#{type_in_code} vs #{type}. Ensure to use valid type in #{path} or ensure that you use " \
          "a valid syntax: #{TYPES.dig(type, :example)}"
      end

      # We accept an array of defaults as some features are undefined
      # and have `default_enabled: true/false`
      unless Array(default_enabled).include?(default_enabled_in_code)
        # Raise exception in test and dev
        raise Feature::InvalidFeatureFlagError, "The `default_enabled:` of `#{key}` is not equal to config: " \
          "#{default_enabled_in_code} vs #{default_enabled}. Ensure to update #{path}"
      end
    end

    def to_h
      attributes
    end

    class << self
      def paths
        @paths ||= [Rails.root.join('config', 'feature_flags', '**', '*.yml')]
      end

      def definitions
        @definitions ||= {}
      end

      def load_all!
        definitions.clear

        paths.each do |glob_path|
          load_all_from_path!(glob_path)
        end

        definitions
      end

      def valid_usage!(key, type:, default_enabled:)
        if definition = definitions[key.to_sym]
          definition.valid_usage!(type_in_code: type, default_enabled_in_code: default_enabled)
        elsif type_definition = self::TYPES[type]
          raise InvalidFeatureFlagError, "Missing feature definition for `#{key}`" unless type_definition[:optional]
        else
          raise InvalidFeatureFlagError, "Unknown feature flag type used: `#{type}`"
        end
      end

      private

      def load_from_file(path)
        definition = File.read(path)
        definition = YAML.safe_load(definition)
        definition.deep_symbolize_keys!

        self.new(path, definition).tap(&:validate!)
      rescue => e
        raise Feature::InvalidFeatureFlagError, "Invalid definition for `#{path}`: #{e.message}"
      end

      def load_all_from_path!(glob_path)
        Dir.glob(glob_path).each do |path|
          definition = load_from_file(path)

          if previous = definitions[definition.key]
            raise InvalidFeatureFlagError, "Feature flag '#{definition.key}' is already defined in '#{previous.path}'"
          end

          definitions[definition.key] = definition
        end
      end
    end
  end
end

Feature::Definition.prepend_if_ee('EE::Feature::Definition')
