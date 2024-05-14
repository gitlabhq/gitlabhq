# frozen_string_literal: true

class AddIndexEnvironmentsNameWithoutType < Gitlab::Database::Migration[2.2]
  milestone '16.10'

  disable_ddl_transaction!

  INDEX_NAME = 'index_environments_name_without_type'

  def up
    add_concurrent_index :environments,
      "project_id, lower(ltrim(ltrim(name, environment_type), '/')) varchar_pattern_ops, state", name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :environments, INDEX_NAME
  end
end
