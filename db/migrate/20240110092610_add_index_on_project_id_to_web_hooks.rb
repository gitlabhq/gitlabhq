# frozen_string_literal: true

class AddIndexOnProjectIdToWebHooks < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.9'

  TABLE_NAME = :web_hooks
  INDEX_NAME = 'index_web_hooks_on_project_id_and_id'
  CLAUSE = "((type)::text = 'ProjectHook'::text)"

  def up
    add_concurrent_index TABLE_NAME, [:project_id, :id], name: INDEX_NAME, where: CLAUSE
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end
end
