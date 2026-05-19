# frozen_string_literal: true

class ReplaceForeignKeyOnAchievementUploadStates < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.0'

  SOURCE_TABLE_NAME = :achievement_upload_states
  NEW_TARGET_TABLE = :achievement_uploads
  OLD_TARGET_TABLE = :uploads_archived
  COLUMN = :achievement_upload_id
  OLD_FOREIGN_KEY_NAME = :fk_dd96a3fb92
  NEW_FOREIGN_KEY_NAME = :fk_rails_dd96a3fb92

  def up
    add_concurrent_foreign_key SOURCE_TABLE_NAME, NEW_TARGET_TABLE,
      column: COLUMN, on_delete: :cascade,
      name: NEW_FOREIGN_KEY_NAME, reverse_lock_order: true

    with_lock_retries do
      remove_foreign_key_if_exists SOURCE_TABLE_NAME, column: COLUMN,
        name: OLD_FOREIGN_KEY_NAME, reverse_lock_order: true
    end
  end

  def down
    add_concurrent_foreign_key SOURCE_TABLE_NAME, OLD_TARGET_TABLE,
      column: COLUMN, on_delete: :cascade, name: OLD_FOREIGN_KEY_NAME

    with_lock_retries do
      remove_foreign_key_if_exists SOURCE_TABLE_NAME, column: COLUMN,
        name: NEW_FOREIGN_KEY_NAME, reverse_lock_order: true
    end
  end
end
