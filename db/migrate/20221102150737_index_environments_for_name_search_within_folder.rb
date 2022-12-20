# frozen_string_literal: true

class IndexEnvironmentsForNameSearchWithinFolder < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_environments_for_name_search_within_folder'

  def up
    add_concurrent_index :environments,
      "project_id, lower(ltrim(name, environment_type || '/')) varchar_pattern_ops, state", name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :environments, INDEX_NAME
  end
end
