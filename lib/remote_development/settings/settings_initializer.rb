# frozen_string_literal: true

module RemoteDevelopment
  module Settings
    class SettingsInitializer
      include Messages

      # @param [Hash] value
      # @return [Hash]
      # @raise [RuntimeError]
      def self.init(value)
        value[:settings] = {}
        value[:setting_types] = {}

        DefaultSettings.default_settings.each do |setting_name, setting_value_and_type|
          unless setting_value_and_type.is_a?(Array) && setting_value_and_type.length == 2
            raise "Remote Development Setting entry for '#{setting_name}' must " \
              "be a two-element array containing the value and type."
          end

          setting_value, setting_type = setting_value_and_type

          unless setting_type.is_a?(Class)
            raise "Remote Development Setting type for '#{setting_name}' " \
              "must be a class, but it was a #{setting_type.class}."
          end

          if !setting_value.nil? && !setting_value.is_a?(setting_type)
            # NOTE: We are raising an exception here instead of returning a Result.err, because this is
            # a coding syntax error in the 'default_settings', not a user or data error.
            raise "Remote Development Setting '#{setting_name}' has a type of '#{setting_value.class}', " \
              "which does not match declared type of '#{setting_type}'."
          end

          value[:settings][setting_name] = setting_value
          value[:setting_types][setting_name] = setting_type
        end

        value
      end
    end
  end
end
