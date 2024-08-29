# frozen_string_literal: true

class AddIndexOnPagesDeploymentExpiresAt < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  disable_ddl_transaction!

  INDEX = 'index_pages_deployments_on_expires_at'

  def up
    add_concurrent_index :pages_deployments,
      [:expires_at, :id],
      where: 'expires_at IS NOT NULL',
      name: INDEX
  end

  def down
    remove_concurrent_index_by_name :pages_deployments, INDEX
  end
end
