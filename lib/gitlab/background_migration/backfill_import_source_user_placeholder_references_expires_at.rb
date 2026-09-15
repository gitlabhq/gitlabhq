# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillImportSourceUserPlaceholderReferencesExpiresAt < BatchedMigrationJob
      cursor :id
      operation_name :backfill_import_source_user_placeholder_references_expires_at
      feature_category :importers

      def perform
        each_sub_batch do |sub_batch|
          sub_batch.where(expires_at: nil).update_all("expires_at = NOW() + INTERVAL '1 year'")
        end
      end
    end
  end
end
