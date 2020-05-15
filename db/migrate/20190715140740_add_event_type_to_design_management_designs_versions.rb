# frozen_string_literal: true

# This migration sets up a event enum on the DesignsVersions join table
class AddEventTypeToDesignManagementDesignsVersions < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  # We disable these cops here because adding this column is safe. The table does not
  # have any data in it.
  # rubocop: disable Migration/AddIndex
  def up
    add_column(:design_management_designs_versions, :event, :integer,
               limit: 2,
               null: false,
               default: 0)
    add_index(:design_management_designs_versions, :event)
  end

  # rubocop: disable Migration/RemoveIndex
  def down
    remove_index(:design_management_designs_versions, :event)
    remove_column(:design_management_designs_versions, :event)
  end
end
