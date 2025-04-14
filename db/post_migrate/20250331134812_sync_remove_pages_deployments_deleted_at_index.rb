# frozen_string_literal: true

class SyncRemovePagesDeploymentsDeletedAtIndex < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.11'

  INDEX_NAME = 'pages_deployments_deleted_at_index'
  COLUMNS = [:id, :project_id, :path_prefix]

  def up
    remove_concurrent_index_by_name :pages_deployments, name: INDEX_NAME
  end

  def down
    add_concurrent_index :pages_deployments, COLUMNS, where: 'deleted_at IS NULL', name: INDEX_NAME
  end
end
