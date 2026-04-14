# frozen_string_literal: true

class AddIndexRoutesOnIdForTopLevelPaths < Gitlab::Database::Migration[2.3]
  milestone '18.11'
  disable_ddl_transaction!

  INDEX_NAME = 'index_routes_on_id_for_top_level_paths'

  def up
    add_concurrent_index :routes, :id, name: INDEX_NAME, where: "strpos(path, '/') = 0"
  end

  def down
    remove_concurrent_index_by_name :routes, INDEX_NAME
  end
end
