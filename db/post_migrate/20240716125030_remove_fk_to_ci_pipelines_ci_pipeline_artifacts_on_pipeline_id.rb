# frozen_string_literal: true

class RemoveFkToCiPipelinesCiPipelineArtifactsOnPipelineId < Gitlab::Database::Migration[2.2]
  milestone '17.3'
  disable_ddl_transaction!

  SOURCE_TABLE_NAME = :ci_pipeline_artifacts
  TARGET_TABLE_NAME = :ci_pipelines
  COLUMN = :pipeline_id
  TARGET_COLUMN = :id
  FK_NAME = :fk_rails_a9e811a466

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(
        SOURCE_TABLE_NAME,
        TARGET_TABLE_NAME,
        name: FK_NAME,
        reverse_lock_order: true
      )
    end
  end

  def down
    add_concurrent_foreign_key(
      SOURCE_TABLE_NAME,
      TARGET_TABLE_NAME,
      column: COLUMN,
      target_column: TARGET_COLUMN,
      validate: true,
      reverse_lock_order: true,
      on_delete: :cascade,
      name: FK_NAME
    )
  end
end
