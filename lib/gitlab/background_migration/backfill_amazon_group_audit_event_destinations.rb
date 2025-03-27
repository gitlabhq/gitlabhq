# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillAmazonGroupAuditEventDestinations < BatchedMigrationJob
      feature_category :audit_events

      def perform
        # CE implementation is a no-op
      end
    end
  end
end

Gitlab::BackgroundMigration::BackfillAmazonGroupAuditEventDestinations.prepend_mod
