# frozen_string_literal: true

class RemoveIndexIssuesOnProjectIdAndExternalKeyConcurrently < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  INDEX_NAME = 'index_issues_on_project_id_and_external_key'

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :issues, name: INDEX_NAME
  end

  def down
    add_concurrent_index :issues, [:project_id, :external_key], name: INDEX_NAME,
      where: 'external_key IS NOT NULL', unique: true
  end
end
