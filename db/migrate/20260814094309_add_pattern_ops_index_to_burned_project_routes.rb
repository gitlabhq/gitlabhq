# frozen_string_literal: true

class AddPatternOpsIndexToBurnedProjectRoutes < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  disable_ddl_transaction!

  INDEX_NAME = 'index_burned_project_routes_on_org_id_lower_path_pattern'

  def up
    add_concurrent_index(
      :burned_project_routes,
      'organization_id, lower(path) text_pattern_ops',
      name: INDEX_NAME
    )
  end

  def down
    remove_concurrent_index_by_name(:burned_project_routes, INDEX_NAME)
  end
end
