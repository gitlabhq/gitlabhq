# frozen_string_literal: true

class AddIndexesToDeploymentsOnProjectIdAndRef < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'partial_index_deployments_for_project_id_and_tag'.freeze

  disable_ddl_transaction!

  def up
    add_concurrent_index :deployments, [:project_id, :ref]
    add_concurrent_index :deployments, [:project_id], where: 'tag IS TRUE', name: INDEX_NAME
  end

  def down
    remove_concurrent_index :deployments, [:project_id, :ref]
    remove_concurrent_index :deployments, [:project_id], where: 'tag IS TRUE', name: INDEX_NAME
  end
end
