# rubocop:disable RemoveIndex
class AddIndexToLabelsForTypeAndProject < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :labels, [:type, :project_id]
  end

  def down
    remove_index :labels, [:type, :project_id] if index_exists? :labels, [:type, :project_id]
  end
end
