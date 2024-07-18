# frozen_string_literal: true

module RemoteDevelopment
  module Settings
    class SettingsInitializer
      def self.init(context)
        context => { requested_setting_names: Array => requested_setting_names }

        context[:settings], context[:setting_types] = Gitlab::Fp::Settings::DefaultSettingsParser.parse(
          module_name: "Remote Development",
          requested_setting_names: requested_setting_names,
          default_settings: DefaultSettings.default_settings,
          mutually_dependent_settings_groups: [
            [:full_reconciliation_interval_seconds, :partial_reconciliation_interval_seconds]
          ]
        )

        # NOTE: This is context which is required by shared Gitlab::Fp::Settings::EnvVarOverrideProcessor class
        context[:env_var_prefix] = "GITLAB_REMOTE_DEVELOPMENT"
        context[:env_var_failed_message_class] =
          RemoteDevelopment::Settings::Messages::SettingsEnvironmentVariableOverrideFailed

        context
      end
    end
  end
end
