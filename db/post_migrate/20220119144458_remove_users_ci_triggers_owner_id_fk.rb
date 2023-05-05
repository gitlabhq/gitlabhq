# frozen_string_literal: true

class RemoveUsersCiTriggersOwnerIdFk < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      execute('LOCK users, ci_triggers IN ACCESS EXCLUSIVE MODE')

      remove_foreign_key_if_exists(:ci_triggers, :users, name: "fk_e8e10d1964")
    end
  end

  def down
    add_concurrent_foreign_key(:ci_triggers, :users, name: "fk_e8e10d1964", column: :owner_id, target_column: :id, on_delete: :cascade)
  end
end
