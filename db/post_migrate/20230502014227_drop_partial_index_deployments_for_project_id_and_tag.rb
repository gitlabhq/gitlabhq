# frozen_string_literal: true

class DropPartialIndexDeploymentsForProjectIdAndTag < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'partial_index_deployments_for_project_id_and_tag'

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :deployments, name: INDEX_NAME
  end

  def down
    # This is based on the following `CREATE INDEX` command in db/init_structure.sql:
    # CREATE INDEX partial_index_deployments_for_project_id_and_tag ON deployments
    #   USING btree (project_id) WHERE (tag IS TRUE);
    add_concurrent_index :deployments, :project_id, name: INDEX_NAME, where: 'tag IS TRUE'
  end
end
