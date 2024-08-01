# frozen_string_literal: true

module RemoteDevelopment
  module Settings
    class CurrentSettingsReader
      include Messages

      RELEVANT_SETTING_NAMES = %i[
        default_branch_name
      ].freeze

      # @param [Hash] context
      # @return [Gitlab::Fp::Result]
      def self.read(context)
        err_result = nil

        context[:settings].each_key do |setting_name|
          next unless RELEVANT_SETTING_NAMES.include?(setting_name)

          raise "Invalid CurrentSettings entry specified" unless Gitlab::CurrentSettings.respond_to?(setting_name)

          current_setting_value = Gitlab::CurrentSettings.send(setting_name) # rubocop:disable GitlabSecurity/PublicSend -- No other way to programatically call dynamic class method

          next if current_setting_value.nil?

          setting_type = context[:setting_types][setting_name]

          unless current_setting_value.is_a?(setting_type)
            # err_result will be set to a non-nil Gitlab::Fp::Result.err if type check fails
            err_result = Gitlab::Fp::Result.err(SettingsCurrentSettingsReadFailed.new(
              details: "Gitlab::CurrentSettings.#{setting_name} type of '#{current_setting_value.class}' " \
                "did not match initialized Remote Development Settings type of '#{setting_type}'."
            ))
          end

          # CurrentSettings entry of correct type found for declared default setting, use its value as override
          context[:settings][setting_name] = current_setting_value
        end

        return err_result if err_result

        Gitlab::Fp::Result.ok(context)
      end
    end
  end
end
