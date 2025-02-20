# frozen_string_literal: true

class AddForeignKeyRoutesNamespaceId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.10'

  SOURCE_TABLE = :routes
  TARGET_TABLE = :namespaces
  COLUMN = :namespace_id

  def up
    add_concurrent_foreign_key(
      SOURCE_TABLE,
      TARGET_TABLE,
      column: COLUMN,
      validate: false,
      on_delete: :cascade
    )
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists(SOURCE_TABLE, TARGET_TABLE, column: COLUMN)
    end
  end
end
