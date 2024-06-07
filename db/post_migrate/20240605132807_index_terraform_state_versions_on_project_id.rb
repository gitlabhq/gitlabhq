# frozen_string_literal: true

class IndexTerraformStateVersionsOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.1'
  disable_ddl_transaction!

  INDEX_NAME = 'index_terraform_state_versions_on_project_id'

  def up
    add_concurrent_index :terraform_state_versions, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :terraform_state_versions, INDEX_NAME
  end
end
