# frozen_string_literal: true

class FinalizeQueueBackfillProjectRelationExportUploadsProjectId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '18.1'

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillProjectRelationExportUploadsProjectId',
      table_name: :project_relation_export_uploads,
      column_name: :id,
      job_arguments: [
        :project_id,
        :project_relation_exports,
        :project_id,
        :project_relation_export_id
      ],
      finalize: true
    )
  end

  def down
    # no-op
  end
end
