# frozen_string_literal: true

class AddProjectIdFkToTimelogs < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_timelogs_on_project_id_and_spent_at'

  disable_ddl_transaction!

  def up
    add_concurrent_index :timelogs, [:project_id, :spent_at], name: INDEX_NAME
    add_concurrent_foreign_key :timelogs, :projects, column: :project_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :timelogs, column: :project_id
    end
    remove_concurrent_index_by_name :timelogs, INDEX_NAME
  end
end
