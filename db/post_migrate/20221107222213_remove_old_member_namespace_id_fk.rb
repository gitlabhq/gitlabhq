# frozen_string_literal: true

class RemoveOldMemberNamespaceIdFk < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  TARGET_COLUMN = :member_namespace_id

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:members, column: TARGET_COLUMN, name: fk_name(TARGET_COLUMN))
    end
  end

  def down
    add_concurrent_foreign_key(
      :members,
      :namespaces,
      column: TARGET_COLUMN,
      name: fk_name(TARGET_COLUMN),
      on_delete: :nullify
    )
  end

  def fk_name(column_name)
    # generate a FK name
    concurrent_foreign_key_name(:members, column_name)
  end
end
