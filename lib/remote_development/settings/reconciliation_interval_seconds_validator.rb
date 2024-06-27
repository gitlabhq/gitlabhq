# frozen_string_literal: true

module RemoteDevelopment
  module Settings
    class ReconciliationIntervalSecondsValidator
      include Messages

      # @param [Hash] context
      # @return [Gitlab::Fp::Result]
      def self.validate(context)
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
