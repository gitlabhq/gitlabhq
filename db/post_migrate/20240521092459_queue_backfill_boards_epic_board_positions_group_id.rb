# frozen_string_literal: true

class QueueBackfillBoardsEpicBoardPositionsGroupId < Gitlab::Database::Migration[2.2]
  milestone '17.1'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  MIGRATION = "BackfillBoardsEpicBoardPositionsGroupId"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :boards_epic_board_positions,
      :id,
      :group_id,
      :boards_epic_boards,
      :group_id,
      :epic_board_id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(
      MIGRATION,
      :boards_epic_board_positions,
      :id,
      [
        :group_id,
        :boards_epic_boards,
        :group_id,
        :epic_board_id
      ]
    )
  end
end
