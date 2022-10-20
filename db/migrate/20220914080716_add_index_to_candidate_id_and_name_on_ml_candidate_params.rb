# frozen_string_literal: true

class AddIndexToCandidateIdAndNameOnMlCandidateParams < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_ml_candidate_params_on_candidate_id_on_name'

  def up
    add_concurrent_index :ml_candidate_params, [:candidate_id, :name], unique: true, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name(:ml_candidate_params, INDEX_NAME)
  end
end
