# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class DropIndexDeploymentsOnEnvironmentIdAndIidAndProjectId < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_deployments_on_environment_id_and_iid_and_project_id'

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :deployments, name: INDEX_NAME
  end

  def down
    # This is based on the following `CREATE INDEX` command in db/init_structure.sql:
    # CREATE INDEX index_deployments_on_environment_id_and_iid_and_project_id ON deployments
    #   USING btree (environment_id, iid, project_id);
    add_concurrent_index :deployments, %i[environment_id iid project_id], name: INDEX_NAME
  end
end
