# frozen_string_literal: true

class AddIndexSnippetsOnProjectIdAndTitle < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_snippets_on_project_id_and_title'

  def up
    add_concurrent_index :snippets, [:project_id, :title], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :snippets, name: INDEX_NAME
  end
end
