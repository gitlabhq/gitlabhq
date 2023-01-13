# frozen_string_literal: true

class ChangeKeysRelationToSshSignatures < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  TARGET_COLUMN = :key_id

  def up
    add_concurrent_foreign_key(
      :ssh_signatures,
      :keys,
      column: :key_id,
      name: fk_name("#{TARGET_COLUMN}_nullify"),
      on_delete: :nullify
    )

    with_lock_retries do
      remove_foreign_key_if_exists(:ssh_signatures, column: TARGET_COLUMN, name: fk_name(TARGET_COLUMN))
    end
  end

  def down
    add_concurrent_foreign_key(
      :ssh_signatures,
      :keys,
      column: :key_id,
      name: fk_name(TARGET_COLUMN),
      on_delete: :cascade
    )

    with_lock_retries do
      remove_foreign_key_if_exists(:ssh_signatures, column: TARGET_COLUMN, name: fk_name("#{TARGET_COLUMN}_nullify"))
    end
  end

  private

  def fk_name(column_name)
    concurrent_foreign_key_name(:ssh_signatures, column_name)
  end
end
