# frozen_string_literal: true

class DropClustersApplicationsRunnersCiRunnersFk < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:clusters_applications_runners, :ci_runners, name: 'fk_02de2ded36')
    end
  end

  def down
    add_concurrent_foreign_key(:clusters_applications_runners, :ci_runners, name: 'fk_02de2ded36', column: :runner_id, target_column: :id, on_delete: 'set null')
  end
end
