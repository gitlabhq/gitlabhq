# frozen_string_literal: true

class IndexDastSiteProfileSecretVariablesOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.1'
  disable_ddl_transaction!

  INDEX_NAME = 'index_dast_site_profile_secret_variables_on_project_id'

  def up
    add_concurrent_index :dast_site_profile_secret_variables, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :dast_site_profile_secret_variables, INDEX_NAME
  end
end
