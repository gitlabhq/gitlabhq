# frozen_string_literal: true

class AddProjectsO11yLogsFk < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.4'

  def up
    add_concurrent_foreign_key :observability_logs_issues_connections,
      :projects,
      column: :project_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :observability_logs_issues_connections, column: :project_id
    end
  end
end
