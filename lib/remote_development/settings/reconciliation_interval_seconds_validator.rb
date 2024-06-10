# frozen_string_literal: true

module RemoteDevelopment
  module Settings
    class ReconciliationIntervalSecondsValidator
      include Messages

      # @param [Hash] value
      # @return [Result]
      def self.validate(value)
        value => {
          settings: {
            full_reconciliation_interval_seconds: Integer => full_reconciliation_interval_seconds,
            partial_reconciliation_interval_seconds: Integer => partial_reconciliation_interval_seconds
          }
        }

        unless partial_reconciliation_interval_seconds > 0
          return Result.err(SettingsPartialReconciliationIntervalSecondsValidationFailed.new(
            details: "Partial reconciliation interval must be greater than zero")
                           )
        end

        unless full_reconciliation_interval_seconds > 0
          return Result.err(SettingsFullReconciliationIntervalSecondsValidationFailed.new(
            details: "Full reconciliation interval must be greater than zero")
                           )
        end

        if full_reconciliation_interval_seconds <= partial_reconciliation_interval_seconds
          return Result.err(SettingsPartialReconciliationIntervalSecondsValidationFailed.new(
            details: "Partial reconciliation interval must be less than full reconciliation interval")
                           )
        end

        Result.ok(value)
      end
    end
  end
end
