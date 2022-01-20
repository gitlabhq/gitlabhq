# frozen_string_literal: true

class RemoveProjectsCiSourcesPipelinesSourceProjectIdFk < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      execute('LOCK projects, ci_sources_pipelines IN ACCESS EXCLUSIVE MODE')

      remove_foreign_key_if_exists(:ci_sources_pipelines, :projects, name: "fk_acd9737679")
    end
  end

  def down
    add_concurrent_foreign_key(:ci_sources_pipelines, :projects, name: "fk_acd9737679", column: :source_project_id, target_column: :id, on_delete: :cascade)
  end
end
