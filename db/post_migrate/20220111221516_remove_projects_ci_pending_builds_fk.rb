# frozen_string_literal: true

class RemoveProjectsCiPendingBuildsFk < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:ci_pending_builds, :projects, name: "fk_rails_480669c3b3")
    end
  end

  def down
    add_concurrent_foreign_key(:ci_pending_builds, :projects, name: "fk_rails_480669c3b3", column: :project_id, target_column: :id, on_delete: "cascade")
  end
end
