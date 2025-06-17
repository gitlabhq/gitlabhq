# frozen_string_literal: true

class FinalizeBackfillBoardsEpicListUserPreferencesGroupId < Gitlab::Database::Migration[2.3]
  milestone '18.1'
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillBoardsEpicListUserPreferencesGroupId',
      table_name: :boards_epic_list_user_preferences,
      column_name: :id,
      job_arguments: [:group_id, :boards_epic_lists, :group_id, :epic_list_id],
      finalize: true
    )
  end

  def down; end
end
