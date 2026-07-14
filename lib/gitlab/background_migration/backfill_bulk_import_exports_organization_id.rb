# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillBulkImportExportsOrganizationId < BatchedMigrationJob
      operation_name :backfill_bulk_import_exports_organization_id
      feature_category :importers

      def perform
        each_sub_batch do |sub_batch|
          # Updating the row executes the 'trigger_bulk_import_exports_sharding_key' which derives
          # and sets organization_id from the related project or group.
          # So we just touch `updated_at` and let the trigger figure out the correct value.
          sub_batch
            .where(organization_id: nil)
            .update_all('updated_at = updated_at')
        end
      end
    end
  end
end
