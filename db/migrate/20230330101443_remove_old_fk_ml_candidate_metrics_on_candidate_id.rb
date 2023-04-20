# frozen_string_literal: true

class RemoveOldFkMlCandidateMetricsOnCandidateId < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  OLD_CONSTRAINT_NAME = 'fk_rails_efb613a25a'

  def up
    remove_foreign_key_if_exists(:ml_candidate_metrics, column: :candidate_id, name: OLD_CONSTRAINT_NAME)
  end

  def down
    add_concurrent_foreign_key(
      :ml_candidate_metrics,
      :ml_candidates,
      column: :candidate_id,
      validate: false,
      name: OLD_CONSTRAINT_NAME
    )
  end
end
