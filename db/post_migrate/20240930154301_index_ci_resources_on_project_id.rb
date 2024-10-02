# frozen_string_literal: true

class IndexCiResourcesOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.5'
  disable_ddl_transaction!

  INDEX_NAME = 'index_ci_resources_on_project_id'

  def up
    add_concurrent_index :ci_resources, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :ci_resources, INDEX_NAME
  end
end
