# frozen_string_literal: true

class IndexMlCandidateParamsOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.4'
  disable_ddl_transaction!

  INDEX_NAME = 'index_ml_candidate_params_on_project_id'

  def up
    add_concurrent_index :ml_candidate_params, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :ml_candidate_params, INDEX_NAME
  end
end
