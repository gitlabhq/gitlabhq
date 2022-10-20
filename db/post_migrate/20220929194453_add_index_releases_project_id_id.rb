# frozen_string_literal: true

class AddIndexReleasesProjectIdId < Gitlab::Database::Migration[2.0]
  INDEX_NAME = 'index_releases_on_project_id_id'

  disable_ddl_transaction!

  def up
    add_concurrent_index :releases, %i[project_id id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :releases, name: INDEX_NAME
  end
end
