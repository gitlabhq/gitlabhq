# frozen_string_literal: true

class RemoveMergeRequestsCiPipelinesMergeRequestIdFk < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    return unless foreign_key_exists?(:ci_pipelines, :merge_requests, name: "fk_a23be95014")

    with_lock_retries do
      execute('LOCK merge_requests, ci_pipelines IN ACCESS EXCLUSIVE MODE') if transaction_open?

      remove_foreign_key_if_exists(:ci_pipelines, :merge_requests, name: "fk_a23be95014")
    end
  end

  def down
    add_concurrent_foreign_key(:ci_pipelines, :merge_requests, name: "fk_a23be95014", column: :merge_request_id, target_column: :id, on_delete: :cascade)
  end
end
