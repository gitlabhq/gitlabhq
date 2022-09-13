# frozen_string_literal: true

# reverts db/migrate/20220901131828_add_environments_project_name_lower_pattern_ops_index.rb
class DropEnvironmentsProjectNameLowerPatternOpsIndex < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_environments_on_project_name_varchar_pattern_ops'

  def up
    remove_concurrent_index_by_name :environments, INDEX_NAME
  end

  def down
    add_concurrent_index :environments, 'project_id, lower(name) varchar_pattern_ops', name: INDEX_NAME
  end
end
