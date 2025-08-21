# frozen_string_literal: true

class FinalizeBulkImportTrackersOrganizationId < Gitlab::Database::Migration[2.2]
  milestone '18.0'
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillBulkImportTrackersOrganizationId',
      table_name: :bulk_import_trackers,
      column_name: :id,
      job_arguments: [
        :organization_id,
        :bulk_import_entities,
        :organization_id,
        :bulk_import_entity_id
      ],
      finalize: true
    )
  end

  def down; end
end
