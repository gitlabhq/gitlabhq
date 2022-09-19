# frozen_string_literal: true

class ChangeMembersNamespaceForeignKeyOnDeleteConstraint < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  TARGET_COLUMN = :member_namespace_id

  def up
    # add the new FK before removing the old one
    add_concurrent_foreign_key(
      :members,
      :namespaces,
      column: TARGET_COLUMN,
      name: fk_name("#{TARGET_COLUMN}_new"),
      on_delete: :cascade,
      validate: false
    )
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists(:members, column: TARGET_COLUMN, name: fk_name("#{TARGET_COLUMN}_new"))
    end
  end

  def fk_name(column_name)
    # generate a FK name
    concurrent_foreign_key_name(:members, column_name)
  end
end
