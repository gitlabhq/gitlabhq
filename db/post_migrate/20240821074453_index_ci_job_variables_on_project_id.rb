# frozen_string_literal: true

class IndexCiJobVariablesOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.4'
  disable_ddl_transaction!

  TABLE_NAME = :ci_job_variables
  INDEX_NAME = :index_ci_job_variables_on_project_id

  def up
    add_concurrent_index(TABLE_NAME, :project_id, name: INDEX_NAME)
  end

  def down
    remove_concurrent_index_by_name(TABLE_NAME, INDEX_NAME)
  end
end
