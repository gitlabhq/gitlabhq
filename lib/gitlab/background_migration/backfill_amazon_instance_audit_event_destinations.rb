# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillAmazonInstanceAuditEventDestinations < BatchedMigrationJob
      feature_category :audit_events

      def perform; end
    end
  end
end

Gitlab::BackgroundMigration::BackfillAmazonInstanceAuditEventDestinations.prepend_mod
