# frozen_string_literal: true

class AddIndexOnShaForInitialDeployments < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  NEW_INDEX_NAME = 'index_deployments_on_environment_status_sha'
  OLD_INDEX_NAME = 'index_deployments_on_environment_id_and_status'

  disable_ddl_transaction!

  def up
    add_concurrent_index :deployments, %i[environment_id status sha], name: NEW_INDEX_NAME
    remove_concurrent_index_by_name :deployments, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index :deployments, %i[environment_id status], name: OLD_INDEX_NAME
    remove_concurrent_index_by_name :services, NEW_INDEX_NAME
  end
end
