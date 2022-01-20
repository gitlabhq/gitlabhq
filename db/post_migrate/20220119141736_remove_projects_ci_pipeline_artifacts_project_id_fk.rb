# frozen_string_literal: true

class RemoveProjectsCiPipelineArtifactsProjectIdFk < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      execute('LOCK projects, ci_pipeline_artifacts IN ACCESS EXCLUSIVE MODE')

      remove_foreign_key_if_exists(:ci_pipeline_artifacts, :projects, name: "fk_rails_4a70390ca6")
    end
  end

  def down
    add_concurrent_foreign_key(:ci_pipeline_artifacts, :projects, name: "fk_rails_4a70390ca6", column: :project_id, target_column: :id, on_delete: :cascade)
  end
end
