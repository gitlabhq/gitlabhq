# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillExternalGroupAuditEventDestinations < BatchedMigrationJob
      # This batched background migration is EE-only,
      # see ee/lib/ee/gitlab/background_migration/backfill_external_group_audit_event_destinations.rb for
      # the actual migration code.

      feature_category :audit_events

      def perform; end
    end
  end
end

Gitlab::BackgroundMigration::BackfillExternalGroupAuditEventDestinations.prepend_mod
