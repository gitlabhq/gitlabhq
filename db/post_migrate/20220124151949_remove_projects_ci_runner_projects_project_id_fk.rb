# frozen_string_literal: true

class RemoveProjectsCiRunnerProjectsProjectIdFk < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    return unless foreign_key_exists?(:ci_runner_projects, :projects, name: "fk_4478a6f1e4")

    with_lock_retries do
      execute('LOCK projects, ci_runner_projects IN ACCESS EXCLUSIVE MODE') if transaction_open?

      remove_foreign_key_if_exists(:ci_runner_projects, :projects, name: "fk_4478a6f1e4")
    end
  end

  def down
    add_concurrent_foreign_key(:ci_runner_projects, :projects, name: "fk_4478a6f1e4", column: :project_id, target_column: :id, on_delete: :cascade)
  end
end
