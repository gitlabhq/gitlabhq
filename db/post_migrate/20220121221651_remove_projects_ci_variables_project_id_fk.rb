# frozen_string_literal: true

class RemoveProjectsCiVariablesProjectIdFk < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    return unless foreign_key_exists?(:ci_variables, :projects, name: "fk_ada5eb64b3")

    with_lock_retries do
      execute('LOCK projects, ci_variables IN ACCESS EXCLUSIVE MODE') if transaction_open?

      remove_foreign_key_if_exists(:ci_variables, :projects, name: "fk_ada5eb64b3")
    end
  end

  def down
    add_concurrent_foreign_key(:ci_variables, :projects, name: "fk_ada5eb64b3", column: :project_id, target_column: :id, on_delete: :cascade)
  end
end
