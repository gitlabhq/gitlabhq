# frozen_string_literal: true

class AddSprintIdIndexToIssues < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :issues, :sprint_id
    add_concurrent_foreign_key :issues, :sprints, column: :sprint_id
  end

  def down
    with_lock_retries do
      remove_foreign_key :issues, column: :sprint_id
    end
    remove_concurrent_index :issues, :sprint_id
  end
end
