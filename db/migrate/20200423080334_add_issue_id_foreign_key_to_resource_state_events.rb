# frozen_string_literal: true

class AddIssueIdForeignKeyToResourceStateEvents < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_foreign_key :resource_state_events, :issues, column: :issue_id, on_delete: :cascade
    end
  end

  def down
    with_lock_retries do
      remove_foreign_key :resource_state_events, column: :issue_id
    end
  end
end
