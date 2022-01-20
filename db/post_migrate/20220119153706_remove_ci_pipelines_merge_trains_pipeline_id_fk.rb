# frozen_string_literal: true

class RemoveCiPipelinesMergeTrainsPipelineIdFk < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      execute('LOCK ci_pipelines, merge_trains IN ACCESS EXCLUSIVE MODE')

      remove_foreign_key_if_exists(:merge_trains, :ci_pipelines, name: "fk_rails_f90820cb08")
    end
  end

  def down
    add_concurrent_foreign_key(:merge_trains, :ci_pipelines, name: "fk_rails_f90820cb08", column: :pipeline_id, target_column: :id, on_delete: :nullify)
  end
end
