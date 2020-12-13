# frozen_string_literal: true

class AddDeploymentsFinderByFinishedAtIndex < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = "index_deployments_on_project_and_finished"

  disable_ddl_transaction!

  def up
    add_concurrent_index :deployments,
      [:project_id, :finished_at],
      where: 'status = 2',
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index :deployments,
      [:project_id, :finished_at],
      where: 'status = 2',
      name: INDEX_NAME
  end
end
