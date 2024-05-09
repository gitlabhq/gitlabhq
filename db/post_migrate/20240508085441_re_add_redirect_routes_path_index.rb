# frozen_string_literal: true

class ReAddRedirectRoutesPathIndex < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.0'

  INDEX_NAME = 'index_redirect_routes_on_path_unique_text_pattern_ops'

  def up
    return if index_exists_by_name?(:redirect_routes, INDEX_NAME)

    add_concurrent_index :redirect_routes, 'LOWER(path) varchar_pattern_ops', unique: true, name: INDEX_NAME
  end

  def down
    # No-op, the index should exist in the schema prior this migration
  end
end
