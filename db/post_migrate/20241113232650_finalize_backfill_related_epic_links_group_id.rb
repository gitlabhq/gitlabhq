# frozen_string_literal: true

class FinalizeBackfillRelatedEpicLinksGroupId < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillRelatedEpicLinksGroupId',
      table_name: :related_epic_links,
      column_name: :id,
      job_arguments: [:group_id, :epics, :group_id, :source_id],
      finalize: true
    )
  end

  def down; end
end
