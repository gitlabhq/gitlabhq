# frozen_string_literal: true

class DropIndexEnvironmentsForNameSearchWithinFolder < Gitlab::Database::Migration[2.2]
  milestone '16.10'
  disable_ddl_transaction!

  INDEX_NAME = 'index_environments_for_name_search_within_folder'

  def up
    remove_concurrent_index_by_name :environments, name: INDEX_NAME
  end

  def down
    # from structure.sql:
    # CREATE INDEX index_environments_for_name_search_within_folder ON environments USING btree
    # (project_id, lower(ltrim((name)::text, ((environment_type)::text || '/'::text))) varchar_pattern_ops, state);
    add_concurrent_index :environments,
      "project_id, lower(ltrim(name, environment_type || '/')) varchar_pattern_ops, state", name: INDEX_NAME
  end
end
