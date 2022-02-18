# frozen_string_literal: true

class RemoveProjectsCiTriggersProjectIdFk < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    return unless foreign_key_exists?(:ci_triggers, :projects, name: "fk_e3e63f966e")

    with_lock_retries do
      execute('LOCK projects, ci_triggers IN ACCESS EXCLUSIVE MODE') if transaction_open?

      remove_foreign_key_if_exists(:ci_triggers, :projects, name: "fk_e3e63f966e")
    end
  end

  def down
    add_concurrent_foreign_key(:ci_triggers, :projects, name: "fk_e3e63f966e", column: :project_id, target_column: :id, on_delete: :cascade)
  end
end
