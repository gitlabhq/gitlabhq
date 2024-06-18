# frozen_string_literal: true

class AddNotValidForeignKeyToNamespacesParent < Gitlab::Database::Migration[2.2]
  TABLE_NAME = :namespaces
  REFERENCING_TABLE_NAME = :namespaces
  COLUMN_NAME = :parent_id

  disable_ddl_transaction!

  milestone '17.1'

  def up
    add_concurrent_foreign_key(
      TABLE_NAME, REFERENCING_TABLE_NAME, column: COLUMN_NAME, on_delete: :restrict, validate: false
    )
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists(TABLE_NAME, column: COLUMN_NAME)
    end
  end
end
