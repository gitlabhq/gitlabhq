# frozen_string_literal: true

class AddUserForeignKeyToCsvIssueImports < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :csv_issue_imports, :users, column: :user_id
  end

  def down
    with_lock_retries do
      remove_foreign_key :csv_issue_imports, column: :user_id
    end
  end
end
