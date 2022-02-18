# frozen_string_literal: true

class RemoveCiPipelinesDastProfilesPipelinesCiPipelineIdFk < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      execute('LOCK ci_pipelines, dast_profiles_pipelines IN ACCESS EXCLUSIVE MODE')

      remove_foreign_key_if_exists(:dast_profiles_pipelines, :ci_pipelines, name: "fk_a60cad829d")
    end
  end

  def down
    add_concurrent_foreign_key(:dast_profiles_pipelines, :ci_pipelines, name: "fk_a60cad829d", column: :ci_pipeline_id, target_column: :id, on_delete: :cascade)
  end
end
