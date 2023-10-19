# frozen_string_literal: true

class AddBuildTimeoutIndex < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_projects_on_id_where_build_timeout_geq_than_2629746'

  def up
    add_concurrent_index :projects, :id, where: 'build_timeout >= 2629746', name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :projects, name: INDEX_NAME
  end
end
