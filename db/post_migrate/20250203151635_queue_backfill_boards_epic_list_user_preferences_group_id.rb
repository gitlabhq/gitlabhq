# frozen_string_literal: true

class QueueBackfillBoardsEpicListUserPreferencesGroupId < Gitlab::Database::Migration[2.2]
  milestone '17.9'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "BackfillBoardsEpicListUserPreferencesGroupId"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :boards_epic_list_user_preferences,
      :id,
      :group_id,
      :boards_epic_lists,
      :group_id,
      :epic_list_id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(
      MIGRATION,
      :boards_epic_list_user_preferences,
      :id,
      [
        :group_id,
        :boards_epic_lists,
        :group_id,
        :epic_list_id
      ]
    )
  end
end
