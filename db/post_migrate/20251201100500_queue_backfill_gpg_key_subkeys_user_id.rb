# frozen_string_literal: true

class QueueBackfillGpgKeySubkeysUserId < Gitlab::Database::Migration[2.3]
  milestone '18.8'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_user

  MIGRATION = "BackfillGpgKeySubkeysUserId"
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :gpg_key_subkeys,
      :id,
      :user_id,
      :gpg_keys,
      :user_id,
      :gpg_key_id,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :gpg_key_subkeys, :id, [
      :user_id,
      :gpg_keys,
      :user_id,
      :gpg_key_id
    ])
  end
end
