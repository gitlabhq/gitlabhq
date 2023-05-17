# frozen_string_literal: true

class CreateFkMlCandidateMetricsOnCandidateId < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  NEW_CONSTRAINT_NAME = 'fk_ml_candidate_metrics_on_candidate_id'

  def up
    add_concurrent_foreign_key(
      :ml_candidate_metrics,
      :ml_candidates,
      column: :candidate_id,
      on_delete: :cascade,
      validate: false,
      name: NEW_CONSTRAINT_NAME
    )
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists(
        :ml_candidate_metrics,
        column: :candidate_id,
        on_delete: :cascade,
        name: NEW_CONSTRAINT_NAME
      )
    end
  end
end
