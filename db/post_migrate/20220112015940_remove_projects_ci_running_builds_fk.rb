# frozen_string_literal: true

class RemoveProjectsCiRunningBuildsFk < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      execute('LOCK projects, ci_running_builds IN ACCESS EXCLUSIVE MODE')

      remove_foreign_key_if_exists(:ci_running_builds, :projects, name: "fk_rails_dc1d0801e8")
    end
  end

  def down
    add_concurrent_foreign_key(:ci_running_builds, :projects, name: "fk_rails_dc1d0801e8", column: :project_id, target_column: :id, on_delete: "cascade")
  end
end
