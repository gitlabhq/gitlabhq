# frozen_string_literal: true

module Feature
  class Definition
    include ::Feature::Shared

    attr_reader :path
    attr_reader :attributes

    VALID_FEATURE_NAME = %r{^#{Gitlab::Regex.sep_by_1('_', /[a-z0-9]+/)}$}

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

      unless VALID_FEATURE_NAME.match?(name)
        raise Feature::InvalidFeatureFlagError, "Feature flag '#{name}' is invalid"
      end

      unless path.present?
        raise Feature::InvalidFeatureFlagError, "Feature flag '#{name}' is missing path"
      end

      unless type.present?
        raise Feature::InvalidFeatureFlagError, "Feature flag '#{name}' is missing `type`. Ensure to update #{path}"
      end

      unless Definition::TYPES.include?(type.to_sym)
        raise Feature::InvalidFeatureFlagError, "Feature flag '#{name}' type '#{type}' is invalid. Ensure to update #{path}"
      end

      if File.basename(path, ".yml") != name || File.basename(File.dirname(path)) != type
        raise Feature::InvalidFeatureFlagError, "Feature flag '#{name}' has an invalid path: '#{path}'. Ensure to update #{path}"
      end

      unless milestone.nil? || milestone.is_a?(String)
        raise InvalidFeatureFlagError, "Feature flag '#{name}' milestone must be a string"
      end

      validate_default_enabled!
    end

    def validate_default_enabled!
      if default_enabled.nil?
        raise Feature::InvalidFeatureFlagError, "Feature flag '#{name}' is missing `default_enabled`. Ensure to update #{path}"
      end

      if default_enabled && !Definition::TYPES.dig(type.to_sym, :can_be_default_enabled)
        raise Feature::InvalidFeatureFlagError, "Feature flag '#{name}' cannot have `default_enabled` set to `true`. Ensure to update #{path}"
      end
    end

    def valid_usage!(type_in_code:)
      return if type_in_code.nil?

      if type != type_in_code.to_s
        # Raise exception in test and dev
        raise Feature::InvalidFeatureFlagError,
          "The given `type: :#{type_in_code}` for `#{key}` is not equal to the " \
          ":#{type} set in its definition file. Ensure to use a valid type in #{path} or ensure that you use " \
          "a valid syntax:\n\n#{TYPES.dig(type.to_sym, :example)}"
      end
    end

    def to_h
      attributes
    end

    def for_upcoming_milestone?
      return false unless milestone

      Gitlab::VersionInfo.parse(milestone + '.999') >= Gitlab.version_info
    end

    def force_log_state_changes?
      attributes[:log_state_changes]
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

      def log_states?(key)
        return false if key == :feature_flag_state_logs
        return false if Feature.disabled?(:feature_flag_state_logs)
        return false unless (feature = get(key))

        feature.force_log_state_changes? || feature.for_upcoming_milestone?
      end

      def valid_usage!(key, type:)
        if definition = get(key)
          definition.valid_usage!(type_in_code: type)
        elsif type.nil?
          raise InvalidFeatureFlagError, "Missing type for undefined feature `#{key}`"
        elsif type_definition = self::TYPES[type]
          raise InvalidFeatureFlagError, "Missing feature definition for `#{key}`" unless type_definition[:optional]
        else
          raise InvalidFeatureFlagError, "Unknown feature flag type used: `#{type}`"
        end
      end

      def default_enabled?(key, default_enabled_if_undefined: nil)
        if definition = get(key)
          definition.default_enabled
        elsif !default_enabled_if_undefined.nil?
          default_enabled_if_undefined
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
