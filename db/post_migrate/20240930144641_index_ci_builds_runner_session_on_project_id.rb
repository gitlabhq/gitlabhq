# frozen_string_literal: true

class IndexCiBuildsRunnerSessionOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.5'
  disable_ddl_transaction!

  INDEX_NAME = 'index_ci_builds_runner_session_on_project_id'

  def up
    add_concurrent_index :ci_builds_runner_session, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :ci_builds_runner_session, INDEX_NAME
  end
end
