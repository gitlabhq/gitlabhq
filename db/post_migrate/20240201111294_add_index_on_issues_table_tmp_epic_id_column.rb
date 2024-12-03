# frozen_string_literal: true

class AddIndexOnIssuesTableTmpEpicIdColumn < Gitlab::Database::Migration[2.2]
  milestone '16.10'
  disable_ddl_transaction!

  INDEX_NAME = "tmp_index_issues_on_tmp_epic_id"

  def up
    # rubocop:disable Migration/PreventIndexCreation -- Legacy migration
    add_concurrent_index :issues, :tmp_epic_id, unique: true, name: INDEX_NAME
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    remove_concurrent_index_by_name :issues, name: INDEX_NAME
  end
end
