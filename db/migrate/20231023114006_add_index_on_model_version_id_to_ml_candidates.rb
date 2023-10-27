# frozen_string_literal: true

class AddIndexOnModelVersionIdToMlCandidates < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_ml_candidates_on_model_version_id'

  def up
    add_concurrent_index :ml_candidates, :model_version_id, name: INDEX_NAME, unique: true
  end

  def down
    remove_concurrent_index_by_name :ml_candidates, name: INDEX_NAME
  end
end
