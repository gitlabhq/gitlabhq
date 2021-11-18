# frozen_string_literal: true

class AddDeploymentsEnvironmentIdAndRefIndex < Gitlab::Database::Migration[1.0]
  INDEX_NAME = 'index_deployments_on_environment_id_and_ref'

  disable_ddl_transaction!

  def up
    add_concurrent_index :deployments, [:environment_id, :ref], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :deployments, INDEX_NAME
  end
end
