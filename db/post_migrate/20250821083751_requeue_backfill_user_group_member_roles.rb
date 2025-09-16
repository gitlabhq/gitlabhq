# frozen_string_literal: true

class RequeueBackfillUserGroupMemberRoles < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "BackfillUserGroupMemberRoles"
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    delete_batched_background_migration(MIGRATION, :members, :id, [])

    queue_batched_background_migration(
      MIGRATION,
      :members,
      :id,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :members, :id, [])
  end
end
