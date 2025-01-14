# frozen_string_literal: true

module WebIde
  module Settings
    class SettingsInitializer
      SETTINGS_DEPENDENCIES = {
        vscode_extensions_gallery_view_model: [:vscode_extensions_gallery_metadata, :vscode_extensions_gallery]
      }.freeze

      # @param [Hash] context
      # @return [Hash]
      # @raise [RuntimeError]
      def self.init(context)
        context => { requested_setting_names: Array => requested_setting_names }

        # NOTE: We override the requested_setting_names to include *all* nested setting dependencies.
        requested_setting_names = Gitlab::Fp::Settings::SettingsDependencyResolver.resolve(
          requested_setting_names,
          SETTINGS_DEPENDENCIES
        )
        context[:requested_setting_names] = requested_setting_names

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
