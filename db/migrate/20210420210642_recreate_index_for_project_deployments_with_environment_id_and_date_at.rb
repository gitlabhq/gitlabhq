# frozen_string_literal: true

# This migration recreates the index that introduced in 20210326035553_add_index_for_project_deployments_with_environment_id_and_updated_at.rb.
class RecreateIndexForProjectDeploymentsWithEnvironmentIdAndDateAt < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  OLD_INDEX_NAME = 'index_deployments_on_project_and_environment_and_updated_at'
  NEW_INDEX_NAME = 'index_deployments_on_project_and_environment_and_updated_at_id'

  def up
    add_concurrent_index :deployments, [:project_id, :environment_id, :updated_at, :id], name: NEW_INDEX_NAME
    remove_concurrent_index_by_name :deployments, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index :deployments, [:project_id, :environment_id, :updated_at], name: OLD_INDEX_NAME
    remove_concurrent_index_by_name :deployments, NEW_INDEX_NAME
  end
end
