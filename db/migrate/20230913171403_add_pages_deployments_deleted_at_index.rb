# frozen_string_literal: true

class AddPagesDeploymentsDeletedAtIndex < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX = 'pages_deployments_deleted_at_index'
  COLUMNS = [:id, :project_id, :path_prefix]

  def up
    add_concurrent_index :pages_deployments,
      COLUMNS,
      where: 'deleted_at IS NULL',
      name: INDEX
  end

  def down
    remove_concurrent_index :pages_deployments, COLUMNS, name: INDEX
  end
end
