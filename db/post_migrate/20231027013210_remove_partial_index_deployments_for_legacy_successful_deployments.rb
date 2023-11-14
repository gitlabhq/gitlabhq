# frozen_string_literal: true

class RemovePartialIndexDeploymentsForLegacySuccessfulDeployments < Gitlab::Database::Migration[2.2]
  INDEX_NAME = 'partial_index_deployments_for_legacy_successful_deployments'

  milestone '16.6'

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :deployments, name: INDEX_NAME
  end

  def down
    # This is based on the following `CREATE INDEX` command in db/init_structure.sql:
    # CREATE INDEX partial_index_deployments_for_legacy_successful_deployments ON deployments
    #   USING btree (id) WHERE ((finished_at IS NULL) AND (status = 2));
    add_concurrent_index :deployments, :id, name: INDEX_NAME, where: '((finished_at IS NULL) AND (status = 2))'
  end
end
