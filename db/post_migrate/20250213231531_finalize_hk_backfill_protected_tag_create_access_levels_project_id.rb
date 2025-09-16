# frozen_string_literal: true

class FinalizeHkBackfillProtectedTagCreateAccessLevelsProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillProtectedTagCreateAccessLevelsProjectId',
      table_name: :protected_tag_create_access_levels,
      column_name: :id,
      job_arguments: [:project_id, :protected_tags, :project_id, :protected_tag_id],
      finalize: true
    )
  end

  def down; end
end
