# frozen_string_literal: true

module RemoteDevelopment
  module Settings
    class CurrentSettingsReader
      include Messages

      # @param [Hash] value
      # @return [Result]
      def self.read(value)
        err_result = nil
        value[:settings].each_key do |setting_name|
          next unless Gitlab::CurrentSettings.respond_to?(setting_name)

          current_setting_value = Gitlab::CurrentSettings.send(setting_name) # rubocop:disable GitlabSecurity/PublicSend -- No other way to programatically call dynamic class method

          next if current_setting_value.nil?

          setting_type = value[:setting_types][setting_name]

          unless current_setting_value.is_a?(setting_type)
            # err_result will be set to a non-nil Result.err if type check fails
            err_result = Result.err(SettingsCurrentSettingsReadFailed.new(
              details: "Gitlab::CurrentSettings.#{setting_name} type of '#{current_setting_value.class}' " \
                "did not match initialized Remote Development Settings type of '#{setting_type}'." # rubocop:disable Layout/LineEndStringConcatenationIndentation -- use default RubyMine formatting
            ))
          end

          # CurrentSettings entry of correct type found for declared default setting, use its value as override
          value[:settings][setting_name] = current_setting_value
        end

        return err_result if err_result

        Result.ok(value)
      end
    end
  end
end
