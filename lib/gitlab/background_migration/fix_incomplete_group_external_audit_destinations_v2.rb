# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class FixIncompleteGroupExternalAuditDestinationsV2 < BatchedMigrationJob
      feature_category :audit_events

      def perform; end
    end
  end
end

Gitlab::BackgroundMigration::FixIncompleteGroupExternalAuditDestinationsV2.prepend_mod
