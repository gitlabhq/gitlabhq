# frozen_string_literal: true

class AddEnvironmentsProjectNameLowerPatternOpsIndex < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_environments_on_project_name_varchar_pattern_ops'

  def up
    add_concurrent_index :environments, 'project_id, lower(name) varchar_pattern_ops', name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :environments, INDEX_NAME
  end
end
