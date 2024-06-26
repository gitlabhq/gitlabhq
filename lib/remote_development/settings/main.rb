# frozen_string_literal: true

module RemoteDevelopment
  module Settings
    class Main
      include Messages
      extend MessageSupport

      # @param [Hash] context
      # @return [Hash]
      # @raise [UnmatchedResultError]
      def self.get_settings(context)
        initial_result = Result.ok(context)

        # The order of the chain determines the precedence of settings. I.e., defaults are
        # overridden by env vars, and any subsequent steps override env vars.
        result =
          initial_result
            .map(SettingsInitializer.method(:init))
            .and_then(CurrentSettingsReader.method(:read))
            .map(ExtensionsGalleryMetadataGenerator.method(:generate))
            # NOTE: EnvVarReader is kept as last step, so it can always be used to easily override any settings for
            #       local or temporary testing.
            .and_then(EnvVarReader.method(:read))
            .and_then(RemoteDevelopment::Settings::ExtensionsGalleryValidator.method(:validate))
            .and_then(RemoteDevelopment::Settings::ExtensionsGalleryMetadataValidator.method(:validate))
            .and_then(RemoteDevelopment::Settings::ReconciliationIntervalSecondsValidator.method(:validate))
            .map(
              # As the final step, return the settings in a SettingsGetSuccessful message
              ->(context) do
                SettingsGetSuccessful.new(settings: context.fetch(:settings))
              end
            )
        # rubocop:disable Lint/DuplicateBranch -- Rubocop doesn't know the branches are different due to destructuring
        case result
        in { err: SettingsEnvironmentVariableReadFailed => message }
          generate_error_response_from_message(message: message, reason: :internal_server_error)
        in { err: SettingsCurrentSettingsReadFailed => message }
          generate_error_response_from_message(message: message, reason: :internal_server_error)
        in { err: SettingsVscodeExtensionsGalleryValidationFailed => message }
          generate_error_response_from_message(message: message, reason: :internal_server_error)
        in { err: SettingsVscodeExtensionsGalleryMetadataValidationFailed => message }
          generate_error_response_from_message(message: message, reason: :internal_server_error)
        in { err: SettingsFullReconciliationIntervalSecondsValidationFailed => message }
          generate_error_response_from_message(message: message, reason: :internal_server_error)
        in { err: SettingsPartialReconciliationIntervalSecondsValidationFailed => message }
          generate_error_response_from_message(message: message, reason: :internal_server_error)
        in { ok: SettingsGetSuccessful => message }
          { settings: message.content.fetch(:settings), status: :success }
        else
          raise UnmatchedResultError.new(result: result)
        end
        # rubocop:enable Lint/DuplicateBranch
      end
    end
  end
end
