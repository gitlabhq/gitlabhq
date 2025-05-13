# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillExternalInstanceAuditEventDestinations < BatchedMigrationJob
      feature_category :audit_events

      def perform; end
    end
  end
end

Gitlab::BackgroundMigration::BackfillExternalInstanceAuditEventDestinations.prepend_mod
