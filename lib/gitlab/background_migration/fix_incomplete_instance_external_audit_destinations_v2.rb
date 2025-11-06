# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Migrates instance-level external audit event destinations to new streaming destinations table
    # Handles corrupted verification tokens by generating new ones when decryption fails
    class FixIncompleteInstanceExternalAuditDestinationsV2 < BatchedMigrationJob
      feature_category :audit_events

      def perform; end
    end
  end
end

Gitlab::BackgroundMigration::FixIncompleteInstanceExternalAuditDestinationsV2.prepend_mod
