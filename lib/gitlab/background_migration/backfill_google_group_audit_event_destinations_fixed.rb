# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillGoogleGroupAuditEventDestinationsFixed < BatchedMigrationJob
      feature_category :audit_events

      def perform
        # This batched background migration is EE-only,
        # see ee/lib/gitlab/background_migration/backfill_google_group_audit_event_destinations_fixed.rb for
        # the actual migration code.
      end
    end
  end
end

Gitlab::BackgroundMigration::BackfillGoogleGroupAuditEventDestinationsFixed.prepend_mod
