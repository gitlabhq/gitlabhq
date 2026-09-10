# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillImportPlaceholderMembershipsRetentionExpiresAt < BatchedMigrationJob
      cursor :id
      operation_name :backfill_import_placeholder_memberships_retention_expires_at
      feature_category :importers

      def perform
        each_sub_batch do |sub_batch|
          sub_batch.where(retention_expires_at: nil)
            .update_all("retention_expires_at = NOW() + INTERVAL '1 year'")
        end
      end
    end
  end
end
