# frozen_string_literal: true

class RemoveBackfillBulkImportExportsOrganizationId < Gitlab::Database::Migration[2.3]
  milestone '19.3'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "BackfillBulkImportExportsOrganizationId"

  def up
    delete_batched_background_migration(MIGRATION, :bulk_import_exports, :id, [])
  end

  def down
    # no-op
  end
end
