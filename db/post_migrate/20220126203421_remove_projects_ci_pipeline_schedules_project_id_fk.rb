# frozen_string_literal: true

class RemoveProjectsCiPipelineSchedulesProjectIdFk < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    return unless foreign_key_exists?(:ci_pipeline_schedules, :projects, name: "fk_8ead60fcc4")

    with_lock_retries do
      execute('LOCK projects, ci_pipeline_schedules IN ACCESS EXCLUSIVE MODE') if transaction_open?

      remove_foreign_key_if_exists(:ci_pipeline_schedules, :projects, name: "fk_8ead60fcc4")
    end
  end

  def down
    add_concurrent_foreign_key(:ci_pipeline_schedules, :projects, name: "fk_8ead60fcc4", column: :project_id, target_column: :id, on_delete: :cascade)
  end
end
