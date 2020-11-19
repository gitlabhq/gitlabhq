# frozen_string_literal: true

class AddProjectForeignKeyToCsvIssueImports < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :csv_issue_imports, :projects, column: :project_id
  end

  def down
    with_lock_retries do
      remove_foreign_key :csv_issue_imports, column: :project_id
    end
  end
end
