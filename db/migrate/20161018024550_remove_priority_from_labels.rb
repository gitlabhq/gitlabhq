# rubocop:disable Migration/RemoveColumn
class RemovePriorityFromLabels < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = true
  DOWNTIME_REASON = 'This migration removes an existing column'

  disable_ddl_transaction!

  def up
    remove_column :labels, :priority, :integer, index: true
  end

  def down
    add_column :labels, :priority, :integer
    add_concurrent_index :labels, :priority
  end
end
