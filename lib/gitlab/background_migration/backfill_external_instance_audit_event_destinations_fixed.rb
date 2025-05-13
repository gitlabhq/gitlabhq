# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillExternalInstanceAuditEventDestinationsFixed < BatchedMigrationJob
      feature_category :audit_events

      def perform
        # This batched background migration is EE-only,
        # see ee/lib/gitlab/background_migration/backfill_external_instance_audit_event_destinations_fixed.rb for
        # the actual migration code.
      end
    end
  end
end

Gitlab::BackgroundMigration::BackfillExternalInstanceAuditEventDestinationsFixed.prepend_mod
