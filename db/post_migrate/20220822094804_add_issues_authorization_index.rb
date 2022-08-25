# frozen_string_literal: true

class AddIssuesAuthorizationIndex < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'idx_open_issues_on_project_and_confidential_and_author_and_id'

  def up
    prepare_async_index :issues, [:project_id, :confidential, :author_id, :id], name: INDEX_NAME, where: 'state_id = 1'
  end

  def down
    unprepare_async_index :issues, INDEX_NAME
  end
end
