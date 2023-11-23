# frozen_string_literal: true

class DropIndexWebHooksOnProjectId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.7'

  INDEX_NAME = :index_web_hooks_on_project_id
  TABLE_NAME = :web_hooks

  def up
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end

  def down
    add_concurrent_index TABLE_NAME, :project_id, name: INDEX_NAME
  end
end
