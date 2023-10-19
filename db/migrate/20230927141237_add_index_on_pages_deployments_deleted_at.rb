# frozen_string_literal: true

class AddIndexOnPagesDeploymentsDeletedAt < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX = 'index_pages_deployments_on_deleted_at'

  def up
    add_concurrent_index :pages_deployments,
      :deleted_at,
      where: 'deleted_at IS NOT NULL',
      name: INDEX
  end

  def down
    remove_concurrent_index :pages_deployments, :deleted_at, name: INDEX
  end
end
