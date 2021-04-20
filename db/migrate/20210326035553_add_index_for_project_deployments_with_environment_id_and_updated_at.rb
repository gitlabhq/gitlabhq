# frozen_string_literal: true

class AddIndexForProjectDeploymentsWithEnvironmentIdAndUpdatedAt < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  INDEX_NAME = 'index_deployments_on_project_and_environment_and_updated_at'

  def up
    add_concurrent_index :deployments, [:project_id, :environment_id, :updated_at], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :deployments, INDEX_NAME
  end
end
