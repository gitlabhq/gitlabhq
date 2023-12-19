# frozen_string_literal: true

class DropIndexDeploymentsOnProjectIdSha < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_deployments_on_project_id_sha'

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :deployments, name: INDEX_NAME
  end

  def down
    # This is based on the following `CREATE INDEX` command in db/init_structure.sql:
    # CREATE INDEX index_deployments_on_project_id_sha ON deployments
    #   USING btree (project_id, sha);
    add_concurrent_index :deployments, %i[project_id sha], name: INDEX_NAME
  end
end
