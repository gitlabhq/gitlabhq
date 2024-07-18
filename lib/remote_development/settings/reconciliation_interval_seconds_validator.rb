# frozen_string_literal: true

module RemoteDevelopment
  module Settings
    class ReconciliationIntervalSecondsValidator
      include Messages

      # @param [Hash] context
      # @return [Gitlab::Fp::Result]
      def self.validate(context)
        # NOTE: We only have to check for the existence of full_reconciliation_interval_seconds,
        #       because if it exists, partial_reconciliation_interval_seconds must also exist,
        #       because they are validated to be mutually_dependent_settings in SettingsInitializer
        unless context.fetch(:requested_setting_names).include?(:full_reconciliation_interval_seconds)
          return Gitlab::Fp::Result.ok(context)
        end

        context => {
          settings: {
            full_reconciliation_interval_seconds: Integer => full_reconciliation_interval_seconds,
            partial_reconciliation_interval_seconds: Integer => partial_reconciliation_interval_seconds
          }
        }

        unless partial_reconciliation_interval_seconds > 0
          return Gitlab::Fp::Result.err(SettingsPartialReconciliationIntervalSecondsValidationFailed.new(
            details: "Partial reconciliation interval must be greater than zero"
          ))
        end

        unless full_reconciliation_interval_seconds > 0
          details = "Full reconciliation interval must be greater than zero"
          return Gitlab::Fp::Result.err(SettingsFullReconciliationIntervalSecondsValidationFailed.new(details: details))
        end

        if full_reconciliation_interval_seconds <= partial_reconciliation_interval_seconds
          details = "Partial reconciliation interval must be less than full reconciliation interval"
          return Gitlab::Fp::Result.err(
            SettingsPartialReconciliationIntervalSecondsValidationFailed.new(details: details)
          )
        end

        Gitlab::Fp::Result.ok(context)
      end
    end
  end
end
