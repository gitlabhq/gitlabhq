# frozen_string_literal: true

class FinalizeBackfillBoardsEpicBoardPositionsGroupId < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillBoardsEpicBoardPositionsGroupId',
      table_name: :boards_epic_board_positions,
      column_name: :id,
      job_arguments: [:group_id, :boards_epic_boards, :group_id, :epic_board_id],
      finalize: true
    )
  end

  def down; end
end
