# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillGoogleInstanceAuditEventDestinations < BatchedMigrationJob
      feature_category :audit_events

      def perform
        # no-op, EE only migration
      end
    end
  end
end

Gitlab::BackgroundMigration::BackfillGoogleInstanceAuditEventDestinations.prepend_mod
