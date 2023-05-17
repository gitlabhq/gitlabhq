# frozen_string_literal: true

class AddIndexOnCiBuildIdToMlCandidates < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_ml_candidates_on_ci_build_id'

  def up
    add_concurrent_index :ml_candidates, :ci_build_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :ml_candidates, name: INDEX_NAME
  end
end
