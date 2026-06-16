# frozen_string_literal: true

class RemoveUploadsArchivedToUsersForeignKey < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.1'

  SOURCE_TABLE_NAME = :uploads_archived
  TARGET_TABLE_NAME = :users
  COLUMN = :uploaded_by_user_id
  FOREIGN_KEY_NAME = :fk_b94f059d73

  def up
    with_lock_retries do
      remove_foreign_key_if_exists SOURCE_TABLE_NAME, column: COLUMN,
        name: FOREIGN_KEY_NAME, reverse_lock_order: true
    end
  end

  def down
    add_concurrent_foreign_key SOURCE_TABLE_NAME, TARGET_TABLE_NAME,
      column: COLUMN, on_delete: :nullify,
      name: FOREIGN_KEY_NAME, reverse_lock_order: true
  end
end
