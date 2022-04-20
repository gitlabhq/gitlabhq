# frozen_string_literal: true

class RemoveCiRunnersCiBuildsRunnerIdFk < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    return unless foreign_key_exists?(:ci_builds, :ci_runners, name: "fk_e4ef9c2f27")

    with_lock_retries do
      execute('LOCK ci_runners, ci_builds IN ACCESS EXCLUSIVE MODE') if transaction_open?

      remove_foreign_key_if_exists(:ci_builds, :ci_runners, name: "fk_e4ef9c2f27")
    end
  end

  def down
    add_concurrent_foreign_key :ci_builds, :ci_runners, name: "fk_e4ef9c2f27", column: :runner_id, target_column: :id, on_delete: :nullify, validate: false
  end
end
