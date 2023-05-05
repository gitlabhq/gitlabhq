# frozen_string_literal: true

class RemoveProjectsCiSourcesPipelinesProjectIdFk < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    return unless foreign_key_exists?(:ci_sources_pipelines, :projects, name: "fk_1e53c97c0a")

    with_lock_retries do
      execute('LOCK projects, ci_sources_pipelines IN ACCESS EXCLUSIVE MODE') if transaction_open?

      remove_foreign_key_if_exists(:ci_sources_pipelines, :projects, name: "fk_1e53c97c0a")
    end
  end

  def down
    add_concurrent_foreign_key(:ci_sources_pipelines, :projects, name: "fk_1e53c97c0a", column: :project_id, target_column: :id, on_delete: :cascade)
  end
end
