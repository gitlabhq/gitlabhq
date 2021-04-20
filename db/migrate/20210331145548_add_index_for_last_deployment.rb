# frozen_string_literal: true

class AddIndexForLastDeployment < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_deployments_on_environment_id_status_and_id'

  disable_ddl_transaction!

  def up
    add_concurrent_index :deployments, [:environment_id, :status, :id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :deployments, INDEX_NAME
  end
end
