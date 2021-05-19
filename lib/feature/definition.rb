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

    TYPES.each do |type, _|
      define_method("#{type}?") do
        attributes[:type].to_sym == type
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

      unless default_enabled_in_code == :yaml || default_enabled == default_enabled_in_code
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
        # We lazily load all definitions
        # The hot reloading might request a feature flag
        # before we can properly call `load_all!`
        @definitions ||= load_all!
      end

      def get(key)
        definitions[key.to_sym]
      end

      def reload!
        @definitions = load_all!
      end

      def has_definition?(key)
        definitions.has_key?(key.to_sym)
      end

      def valid_usage!(key, type:, default_enabled:)
        if definition = get(key)
          definition.valid_usage!(type_in_code: type, default_enabled_in_code: default_enabled)
        elsif type_definition = self::TYPES[type]
          raise InvalidFeatureFlagError, "Missing feature definition for `#{key}`" unless type_definition[:optional]
        else
          raise InvalidFeatureFlagError, "Unknown feature flag type used: `#{type}`"
        end
      end

      def default_enabled?(key)
        if definition = get(key)
          definition.default_enabled
        else
          Gitlab::ErrorTracking.track_and_raise_for_dev_exception(
            InvalidFeatureFlagError.new("The feature flag YAML definition for '#{key}' does not exist"))

          false
        end
      end

      def register_hot_reloader!
        # Reload feature flags on change of this file or any `.yml`
        file_watcher = Rails.configuration.file_watcher.new(reload_files, reload_directories) do
          Feature::Definition.reload!
        end

        Rails.application.reloaders << file_watcher
        Rails.application.reloader.to_run { file_watcher.execute_if_updated }

        file_watcher
      end

      private

      def load_all!
        paths.each_with_object({}) do |glob_path, definitions|
          load_all_from_path!(definitions, glob_path)
        end
      end

      def load_from_file(path)
        definition = File.read(path)
        definition = YAML.safe_load(definition)
        definition.deep_symbolize_keys!

        self.new(path, definition).tap(&:validate!)
      rescue StandardError => e
        raise Feature::InvalidFeatureFlagError, "Invalid definition for `#{path}`: #{e.message}"
      end

      def load_all_from_path!(definitions, glob_path)
        Dir.glob(glob_path).each do |path|
          definition = load_from_file(path)

          if previous = definitions[definition.key]
            raise InvalidFeatureFlagError, "Feature flag '#{definition.key}' is already defined in '#{previous.path}'"
          end

          definitions[definition.key] = definition
        end
      end

      def reload_files
        []
      end

      def reload_directories
        paths.each_with_object({}) do |path, result|
          path = File.dirname(path)
          Dir.glob(path).each do |matching_dir|
            result[matching_dir] = 'yml'
          end
        end
      end
    end
  end
end

Feature::Definition.prepend_mod_with('Feature::Definition')
