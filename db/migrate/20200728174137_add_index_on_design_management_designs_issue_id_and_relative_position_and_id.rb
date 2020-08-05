# frozen_string_literal: true

class AddIndexOnDesignManagementDesignsIssueIdAndRelativePositionAndId < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_design_management_designs_issue_id_relative_position_id'

  disable_ddl_transaction!

  def up
    add_concurrent_index :design_management_designs, [:issue_id, :relative_position, :id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index :design_management_designs, [:issue_id, :relative_position, :id], name: INDEX_NAME
  end
end
