# frozen_string_literal: true

class RemoveUploadStatesFkToUploadsArchived < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.0'

  SOURCE_TABLE_NAME = :upload_states
  OLD_TARGET_TABLE = :uploads_archived
  COLUMN = :upload_id
  FOREIGN_KEY_NAME = :fk_rails_d00f153613

  def up
    with_lock_retries do
      remove_foreign_key_if_exists SOURCE_TABLE_NAME, column: COLUMN,
        name: FOREIGN_KEY_NAME, reverse_lock_order: true
    end
  end

  def down
    add_concurrent_foreign_key SOURCE_TABLE_NAME, OLD_TARGET_TABLE,
      column: COLUMN, on_delete: :cascade,
      name: FOREIGN_KEY_NAME, reverse_lock_order: true
  end
end
