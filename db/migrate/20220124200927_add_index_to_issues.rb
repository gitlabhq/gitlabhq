# frozen_string_literal: true

class AddIndexToIssues < Gitlab::Database::Migration[1.0]
  DOWNTIME = false

  disable_ddl_transaction!

  INDEX_NAME = 'index_issues_on_id_and_weight'

  def up
    add_concurrent_index :issues, [:id, :weight], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :issues, INDEX_NAME
  end
end
