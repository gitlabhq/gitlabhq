# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # This batched background migration is EE-only
    class FixIncompleteInstanceExternalAuditDestinations < BatchedMigrationJob
      feature_category :audit_events

      def perform; end
    end
  end
end

Gitlab::BackgroundMigration::FixIncompleteInstanceExternalAuditDestinations.prepend_mod
