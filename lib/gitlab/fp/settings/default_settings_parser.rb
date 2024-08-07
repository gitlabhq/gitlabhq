# frozen_string_literal: true

module Gitlab
  module Fp
    module Settings
      class DefaultSettingsParser
        # @param [String] module_name
        # @param [Array] requested_setting_names
        # @param [Hash] default_settings
        # @param [Array] mutually_dependent_settings_groups
        # @return [Array<(Hash, Hash)>] settings, setting_types
        # @raise [RuntimeError]
        def self.parse(
          module_name:,
          requested_setting_names:,
          default_settings:,
          mutually_dependent_settings_groups: []
        )
          settings = {}
          setting_types = {}

          default_settings.each do |setting_name, setting_value_and_type|
            next unless requested_setting_names.include?(setting_name)

            unless setting_value_and_type.is_a?(Array) && setting_value_and_type.length == 2
              raise "#{module_name} Setting entry for '#{setting_name}' must " \
                "be a two-element array containing the value and type."
            end

            setting_value, setting_type = setting_value_and_type

            unless setting_type.is_a?(Class) || setting_type == :Boolean
              raise "#{module_name} Setting type for '#{setting_name}' " \
                "must be a class or :Boolean, but it was a #{setting_type.class}."
            end

            validate_setting_type(setting_value, setting_type, setting_name, module_name) unless setting_value.nil?

            settings[setting_name] = setting_value
            setting_types[setting_name] = setting_type
          end

          mutually_dependent_settings_groups.each do |mutually_dependent_settings|
            validate_mutually_dependent_settings(
              requested_setting_names: requested_setting_names,
              mutually_dependent_settings: mutually_dependent_settings,
              default_setting_names: default_settings.keys
            )
          end

          [settings, setting_types]
        end

        # @param [array] requested_setting_names
        # @param [array] mutually_dependent_settings
        # @param [array] default_setting_names
        # @return boolean
        # @raise [RuntimeError]
        def self.validate_mutually_dependent_settings(
          requested_setting_names:,
          mutually_dependent_settings:,
          default_setting_names:
        )

          if (mutually_dependent_settings - default_setting_names).any?
            raise "Unknown mutually dependent setting(s): " \
              "#{(mutually_dependent_settings - default_setting_names).join(', ')}"
          end

          at_least_one_mutually_dependent_setting_exists =
            requested_setting_names.intersect?(mutually_dependent_settings)

          return true unless at_least_one_mutually_dependent_setting_exists

          both_mutually_dependent_settings_exist =
            (requested_setting_names & mutually_dependent_settings).size == mutually_dependent_settings.size

          return true if both_mutually_dependent_settings_exist

          raise "#{mutually_dependent_settings.join(' and ')} " \
            "are mutually dependent and must always be specified together"
        end

        # @param [Object] setting_value
        # @param [Class, Symbol] setting_type
        # @param [Symbol] setting_name
        # @param [String] module_name
        # @return boolean
        # @raise [RuntimeError]
        def self.validate_setting_type(setting_value, setting_type, setting_name, module_name)
          return true if setting_type == :Boolean && (setting_value == true || setting_value == false)

          # noinspection RubyMismatchedArgumentType -- RubyMine type checker doesn't recognize guard clause above
          return true if setting_type != :Boolean && setting_value.is_a?(setting_type)

          # NOTE: We are raising an exception here instead of returning a Result.err, because this is
          # a coding syntax error in the 'default_settings', not a user or data error.
          raise "#{module_name} Setting '#{setting_name}' has a type of '#{setting_value.class}', " \
            "which does not match declared type of '#{setting_type}'."
        end

        private_class_method :validate_mutually_dependent_settings, :validate_setting_type
      end
    end
  end
end
