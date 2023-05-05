# frozen_string_literal: true

class DropCiPipelinesMrMetricsFk < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:merge_request_metrics, :ci_pipelines, name: "fk_rails_33ae169d48")
    end
  end

  def down
    add_concurrent_foreign_key(:merge_request_metrics, :ci_pipelines, name: "fk_rails_33ae169d48", column: :pipeline_id, target_column: :id, on_delete: "cascade")
  end
end
