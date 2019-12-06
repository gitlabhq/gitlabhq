# frozen_string_literal: true

class ChangeUpdatedAtIndexAndAddIndexToIdOnDeployments < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  DOWNTIME = false

  PROJECT_ID_INDEX_PARAMS = [[:project_id, :id], order: { id: :desc }]
  OLD_UPDATED_AT_INDEX_PARAMS = [[:project_id, :updated_at]]
  NEW_UPDATED_AT_INDEX_PARAMS = [[:project_id, :updated_at, :id], order: { updated_at: :desc, id: :desc }]

  def up
    add_concurrent_index :deployments, *NEW_UPDATED_AT_INDEX_PARAMS

    remove_concurrent_index :deployments, *OLD_UPDATED_AT_INDEX_PARAMS

    add_concurrent_index :deployments, *PROJECT_ID_INDEX_PARAMS
  end

  def down
    add_concurrent_index :deployments, *OLD_UPDATED_AT_INDEX_PARAMS

    remove_concurrent_index :deployments, *NEW_UPDATED_AT_INDEX_PARAMS

    remove_concurrent_index :deployments, *PROJECT_ID_INDEX_PARAMS
  end
end
