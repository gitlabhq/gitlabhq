# frozen_string_literal: true

class AddIndexOnDesignManagementDesignsIidProjectId < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  INDEX_NAME = 'index_design_management_designs_on_iid_and_project_id'

  def up
    add_concurrent_index :design_management_designs, [:project_id, :iid],
      name: INDEX_NAME,
      unique: true
  end

  def down
    remove_concurrent_index_by_name :design_management_designs, INDEX_NAME
  end
end
