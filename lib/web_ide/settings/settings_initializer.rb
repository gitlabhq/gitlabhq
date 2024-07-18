# frozen_string_literal: true

module WebIde
  module Settings
    class SettingsInitializer
      # @param [Hash] context
      # @return [Hash]
      # @raise [RuntimeError]
      def self.init(context)
        context => { requested_setting_names: Array => requested_setting_names }

        context[:settings], context[:setting_types] = Gitlab::Fp::Settings::DefaultSettingsParser.parse(
          module_name: "Web IDE",
          requested_setting_names: requested_setting_names,
          default_settings: DefaultSettings.default_settings
        )

        # NOTE: This is context which is required by shared Gitlab::Fp::Settings::EnvVarOverrideProcessor class
        context[:env_var_prefix] = "GITLAB_WEB_IDE"
        context[:env_var_failed_message_class] =
          WebIde::Settings::Messages::SettingsEnvironmentVariableOverrideFailed

        context
      end
    end
  end
end
