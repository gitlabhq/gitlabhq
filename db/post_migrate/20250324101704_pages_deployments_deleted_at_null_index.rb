# frozen_string_literal: true

class PagesDeploymentsDeletedAtNullIndex < Gitlab::Database::Migration[2.2]
  milestone '17.11'
  disable_ddl_transaction!

  INDEX = 'pages_deployments_deleted_at_null_index'
  COLUMNS = [:project_id, :path_prefix, :id]

  def up
    add_concurrent_index :pages_deployments, COLUMNS, where: 'deleted_at IS NULL', name: INDEX
  end

  def down
    remove_concurrent_index_by_name :pages_deployments, INDEX
  end
end
