# frozen_string_literal: true

class AddForeignKeyToOpsFeatureFlagsIssues < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_foreign_key :operations_feature_flags_issues, :issues, column: :issue_id, on_delete: :cascade
    end
  end

  def down
    with_lock_retries do
      remove_foreign_key :operations_feature_flags_issues, column: :issue_id
    end
  end
end
