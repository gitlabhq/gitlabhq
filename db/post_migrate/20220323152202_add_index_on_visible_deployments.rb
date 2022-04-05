# frozen_string_literal: true

class AddIndexOnVisibleDeployments < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_deployments_for_visible_scope'

  def up
    add_concurrent_index :deployments,
      [:environment_id, :finished_at],
      order: { finished_at: :desc },
      where: 'status IN (1, 2, 3, 4, 6)',
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :deployments, INDEX_NAME
  end
end
